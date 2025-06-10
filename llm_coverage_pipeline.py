
"""llm_coverage_pipeline.py

Prototype offline pipeline for LLM‑driven coverage‑directed test generation
============================================================================

This script demonstrates, end‑to‑end, how to:

1. Run an RTL testbench with Synopsys VCS (or any simulator) and collect code /
   functional coverage.
2. Parse the resulting coverage report(s) to identify un‑covered items.
3. Extract the relevant RTL code regions for each coverage gap.
4. Build a *prompt* that gives the LLM the context + targets.
5. Query an **offline** LLM (via HuggingFace Transformers) for a new
   SystemVerilog testcase.
6. Integrate the generated test into the verification environment.
7. Re‑run simulation -> merge coverage -> iterate until the stop criteria
   are met.

The implementation is intentionally *minimal* and framework‑agnostic.  Where
your environment differs (e.g. path names, coverage file formats, simulator
command‑lines, preferred LLM), adapt the TODO sections.

Dependencies
------------
* Python 3.9+
* transformers  (``pip install transformers[torch]``)
* rich          (pretty logging; optional)
* For VCS: Synopsys VCS installed and on ``$PATH``.

Usage
-----
::

   python llm_coverage_pipeline.py \       --design-dir  ./rtl        \       --tb          ./tb/tb_top.sv \       --model       ./models/CodeLlama-7b-hf \       --cov-target  95

The script will iterate until **overall coverage ≥ --cov-target** (default 90)
or until ``--max-iterations`` is reached.

NOTE: All external commands are echoed but *not executed* by default for safety.
Use ``--exec`` to actually run them.

Author: ChatGPT (o3) — June 2025
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Tuple, Dict, Any, Iterable, Optional

try:
    from rich import print
except ImportError:
    pass


# ──────────────────────────────────────────────────────────────────────────────
# Utility helpers
# ──────────────────────────────────────────────────────────────────────────────
def sh(cmd: str, dry_run: bool = True, cwd: Path | None = None) -> None:
    """Execute *cmd* in the shell (or just print if *dry_run*)."""
    if dry_run:
        print(f"[bold_yellow]DRY‑RUN[/] $ {cmd}")
        return
    print(f"[bold_green]EXEC[/]    $ {cmd}")
    subprocess.run(cmd, shell=True, check=True, cwd=cwd)


def read_file_lines(path: Path, start: int, end: int) -> str:
    """Return lines ``[start:end]`` (1‑based, inclusive) from *path*."""
    with path.open() as fh:
        lines = fh.readlines()
    snippet = ''.join(lines[start - 1 : end])
    return snippet


# ──────────────────────────────────────────────────────────────────────────────
# Coverage parsing
# ──────────────────────────────────────────────────────────────────────────────
@dataclass
class CoverageItem:
    """Represents a single uncovered line/branch or functional bucket."""

    file: Path
    line_start: int
    line_end: int
    description: str = "code‑coverage"


def parse_vcs_coverage(report_dir: Path) -> List[CoverageItem]:
    """Very lightweight parser for VCS **ucd** or HTML text export.

    We assume that the user has generated ``cov.txt`` which contains lines like::

        [Not Covered] file: rtl/alu.sv line:120‑123  if (overflow_err && enable)

    Adjust the regex for your exact text export.
    """
    cov_items: List[CoverageItem] = []

    txt = (report_dir / "cov.txt").read_text().splitlines()
    pattern = re.compile(
        r"\[Not Covered\]\s+file:\s*(?P<file>\S+)\s*line:(?P<start>\d+)(?:‑(?P<end>\d+))?\s*(?P<desc>.*)"
    )
    for ln in txt:
        m = pattern.search(ln)
        if not m:
            continue
        f = Path(m["file"]).resolve()
        line_start = int(m["start"])
        line_end = int(m["end"] or m["start"])
        desc = m["desc"].strip() or "code‑coverage"
        cov_items.append(CoverageItem(f, line_start, line_end, desc))
    return cov_items


# ──────────────────────────────────────────────────────────────────────────────
# Prompt construction
# ──────────────────────────────────────────────────────────────────────────────
PROMPT_TEMPLATE = """
You are an expert SystemVerilog verification engineer.  Below is an excerpt of
RTL code marked with **TO_BE_COVERED** comments for code or functional coverage
that has not been hit.  Your task:

1. Explain, briefly, what input sequence or condition would trigger each
   uncovered area.
2. Output a *SystemVerilog* test (module or UVM sequence) that achieves coverage
   for ALL these items.  The test must compile and should include any required
   clock/reset/setup.  Use meaningful names.  End the testbench with $finish.

{code_blocks}

### Provide your reasoning, then the final SystemVerilog code in a single
markdown `````systemverilog````` block.
"""


def build_prompt(items: List[CoverageItem], max_lines_each: int = 20) -> str:
    """Create the LLM prompt with annotated code excerpts."""
    code_parts = []
    for it in items:
        snippet = read_file_lines(it.file, it.line_start, min(it.line_end, it.line_start + max_lines_each))
        annotated = snippet.replace("\n", f"\n// TO_BE_COVERED: {it.description}\n", 1)
        header = f"// File: {it.file.name} Lines {it.line_start}‑{it.line_end}\n"
        code_block = f"```systemverilog\n{header}{annotated}\n```"
        code_parts.append(code_block)
    return PROMPT_TEMPLATE.format(code_blocks="\n\n".join(code_parts))


# ──────────────────────────────────────────────────────────────────────────────
# LLM client (offline, HuggingFace Transformers)
# ──────────────────────────────────────────────────────────────────────────────
class LLMClient:
    """Minimal HF Transformers interface for local generation."""

    def __init__(self, model_path: str, device: str = "cpu") -> None:
        from transformers import AutoModelForCausalLM, AutoTokenizer

        print(f"[blue]Loading model from[/] {model_path}.  This may take a while…")
        self.tokenizer = AutoTokenizer.from_pretrained(model_path)
        self.model = AutoModelForCausalLM.from_pretrained(model_path, device_map=device)

    def generate(self, prompt: str, max_new_tokens: int = 512) -> str:
        import torch

        inputs = self.tokenizer(prompt, return_tensors="pt").to(self.model.device)
        with torch.no_grad():
            out = self.model.generate(
                **inputs,
                max_new_tokens=max_new_tokens,
                temperature=0.7,
                top_p=0.9,
                do_sample=True,
            )
        generated = self.tokenizer.decode(out[0], skip_special_tokens=True)
        # Keep only the new portion (after prompt)
        return generated[len(prompt) :]


# ──────────────────────────────────────────────────────────────────────────────
# Simulation integration
# ──────────────────────────────────────────────────────────────────────────────
def integrate_test(test_code: str, work_dir: Path, iteration: int) -> Path:
    """Write the generated test to a SystemVerilog file inside *work_dir*."""
    test_path = work_dir / f"gen_test_{iteration}.sv"
    test_path.write_text(test_code)
    return test_path


def run_simulation(
    design_dir: Path,
    test_file: Path,
    cov_dir: Path,
    dry_run: bool = True,
    vcs_bin: str = "vcs",
) -> None:
    """Compile & simulate, generating coverage reports in *cov_dir*."""
    cov_dir.mkdir(exist_ok=True, parents=True)
    cmd_compile = f"{vcs_bin} -full64 -t ps +v2k +vcs+lic+wait \"{test_file}\" {design_dir}/**/*.sv -cm line+cond+branch -cm_dir {cov_dir}"""
    cmd_sim = f"./simv -cm_dir {cov_dir}"
    sh(cmd_compile, dry_run)
    sh(cmd_sim, dry_run)


def compute_total_coverage(cov_dir: Path) -> float:
    """Stub: read coverage summary (text) and return total % (0‑100)."""
    summary = cov_dir / "cov.txt"
    if not summary.exists():
        return 0.0
    m = re.search(r"TOTAL\s+coverage:\s+(\d+\.\d+)%", summary.read_text())
    return float(m.group(1)) if m else 0.0


# ──────────────────────────────────────────────────────────────────────────────
# Pipeline driver
# ──────────────────────────────────────────────────────────────────────────────
def main() -> None:
    ap = argparse.ArgumentParser(description="LLM‑driven Coverage Closure Prototype")
    ap.add_argument("--design-dir", required=True, type=Path, help="Path to RTL directory")
    ap.add_argument("--model", required=True, help="HF model path (offline)")
    ap.add_argument("--cov-target", type=float, default=90.0, help="Target total % coverage")
    ap.add_argument("--max-iterations", type=int, default=10)
    ap.add_argument("--exec", action="store_true", help="Actually run sims (otherwise dry‑run)")
    args = ap.parse_args()

    work_root = Path.cwd() / "llm_cov_work"
    work_root.mkdir(exist_ok=True)
    cov_dir = work_root / "coverage"

    llm = LLMClient(args.model)

    total_cov = 0.0
    for it in range(1, args.max_iterations + 1):
        print(f"====== ITERATION {it} ======")
        if it == 1:
            print("[cyan]Initial run to gather baseline coverage…[/]")
        else:
            run_simulation(args.design_dir, test_file, cov_dir / f"iter_{it}" , dry_run=not args.exec)  # from prev test

        # Parse coverage
        cov_items = parse_vcs_coverage(cov_dir / f"iter_{it}")
        if not cov_items:
            print("[green]No uncovered items found — assuming 100% coverage?![/]")
            break

        # Build prompt
        prompt = build_prompt(cov_items[:3])  # focus on up to 3 gaps per round
        llm_response = llm.generate(prompt)
        # Extract the SystemVerilog block from response
        code_match = re.search(r"```systemverilog(.*?)```", llm_response, re.S)
        if not code_match:
            print("[red]LLM output did not contain SystemVerilog block — aborting[/]")
            print(llm_response)
            break
        test_code = code_match.group(1).strip()

        # Integrate & simulate
        test_file = integrate_test(test_code, work_root, it)
        run_simulation(args.design_dir, test_file, cov_dir / f"iter_{it}", dry_run=not args.exec)

        total_cov = compute_total_coverage(cov_dir / f"iter_{it}")
        print(f"[magenta]Coverage after iteration {it}: {total_cov:.2f}%[/]")

        if total_cov >= args.cov_target:
            print("[bold green]Coverage target reached! 🎉[/]")
            break
    else:
        print("[yellow]Max iterations reached without hitting coverage target.[/]")


if __name__ == "__main__":
    main()
