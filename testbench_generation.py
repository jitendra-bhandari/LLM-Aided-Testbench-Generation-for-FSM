#!/usr/bin/env python3
import argparse
import re
from pathlib import Path
import sys
import textwrap
import openai

TB_SYSTEM_PROMPT = """You are an expert hardware verification assistant.
Return ONLY a Verilog testbench. Do NOT include any explanation, apology, markdown,
or prose—just Verilog code. Your first non-whitespace characters MUST be 'module tb();'.

Strict testbench preferences (follow exactly):
- Start with: module tb();
- No `timescale directive.
- At the very top of the first initial block:
    $fsdbDumpfile("waves.fsdb");
    $fsdbDumpvars(0, tb);
- Provide a task-based input driver named apply_input(...).
- Respect reset polarity implied by port names (rst, reset = active-high unless 'n' suffix).
- Provide a clock generator if a clock-like port exists (clk, clk_i, clock).
- Instantiate the DUT exactly (module name and ports) from the RTL provided.
- Provide a short reset sequence and a few stimuli via apply_input.
- End with $finish;.
"""

USER_PROMPT_TEMPLATE = """Create a Verilog testbench for the DUT below.
Output ONLY Verilog code starting with `module tb();` (no markdown fences, no prose).

DUT name: {dut_name}
Raw DUT port header (verbatim from module declaration):
{dut_port_header}

Full RTL from file {filename}:
<RTL>
{rtl}
</RTL>
"""

RETRY_ADVICE = """Your prior output did not meet the requirements.
Now strictly output ONLY Verilog code, starting with 'module tb();' as the first token.
No explanations, no markdown fences, no apologies. Ensure the DUT '{dut_name}' is instantiated.
"""

CODE_BLOCK_REGEX = re.compile(r"```(?:verilog|systemverilog)?\s*(?P<code>[\s\S]*?)```", re.IGNORECASE)
MODULE_DECL_REGEX = re.compile(r"(?s)\bmodule\s+([A-Za-z_]\w*)\s*(\#\s*\([^;]*?\))?\s*\((.*?)\)\s*;", re.MULTILINE)

def parse_dut_info(rtl: str):
    """
    Return (dut_name, dut_port_header) by capturing the first module declaration.
    dut_port_header will include the parentheses content as found, unmodified.
    """
    m = MODULE_DECL_REGEX.search(rtl)
    if not m:
        return None, None
    name = m.group(1)
    param_blk = m.group(2) or ""
    port_blk = m.group(3) or ""
    # Reconstruct a close-to-source header for guidance (not used verbatim as code)
    header = f"module {name} {param_blk}({port_blk});"
    return name, header

def extract_verilog_only(text: str) -> str:
    """
    Prefer fenced code; otherwise trim non-code chatter.
    Keep lines from the first 'module' onwards and drop common apology lines.
    """
    m = CODE_BLOCK_REGEX.search(text)
    if m:
        return m.group("code").strip()

    # Remove likely prose/apologies
    filtered = "\n".join(
        ln for ln in text.splitlines()
        if not re.search(r"(?i)^(i'?m|sorry|please provide|cannot|need the actual rtl|as an ai)", ln.strip())
    )
    lines = filtered.splitlines()
    try:
        start = next(i for i, ln in enumerate(lines) if re.search(r"\bmodule\b", ln))
        code = "\n".join(lines[start:]).strip()
        return code
    except StopIteration:
        return filtered.strip()

def looks_like_tb(verilog: str, dut_name: str | None) -> bool:
    if not verilog:
        return False
    has_tb = re.search(r"\bmodule\s+tb\s*\(", verilog) is not None
    has_fsdb = "$fsdbDumpfile" in verilog and "$fsdbDumpvars" in verilog
    has_finish = "$finish" in verilog
    if dut_name:
        # Heuristic: instance line contains dut_name followed by instance name or #(
        inst_pat = re.compile(rf"\b{re.escape(dut_name)}\b\s*(#\s*\(|[A-Za-z_]\w*\s*\()", re.MULTILINE)
        has_inst = inst_pat.search(verilog) is not None
    else:
        has_inst = True  # if unknown, don't block on this
    return has_tb and has_fsdb and has_finish and has_inst

def build_messages(rtl_text: str, filename: str, extra_instruction: str | None):
    dut_name, dut_port_header = parse_dut_info(rtl_text)
    if not dut_name:
        dut_name = "<UNKNOWN_DUT>"
        dut_port_header = "(could not parse module declaration; infer carefully)."

    user_prompt = USER_PROMPT_TEMPLATE.format(
        dut_name=dut_name,
        dut_port_header=dut_port_header,
        filename=filename,
        rtl=rtl_text
    )

    msgs = [
        {"role": "system", "content": TB_SYSTEM_PROMPT},
        {"role": "user", "content": user_prompt},
    ]
    if extra_instruction:
        msgs.append({"role": "user", "content": f"Extra TB preference: {extra_instruction}"})
    return msgs, dut_name

def call_openai(client, model, messages, temperature, max_tokens):
    return client.chat.completions.create(
        model=model,
        messages=messages,
        temperature=temperature,
        max_tokens=max_tokens,
    )

def main():
    parser = argparse.ArgumentParser(description="Generate a Verilog testbench using gpt-4o and save as <input>_tb.v")
    parser.add_argument("verilog_file", type=Path, help="Path to the input Verilog RTL file")
    parser.add_argument("--api_key", required=True, help="OpenAI API key")
    parser.add_argument("--model", default="gpt-4o", help="Model name (default: gpt-4o)")
    parser.add_argument("--extra", default=None, help="Optional extra instruction for the TB")
    parser.add_argument("--temperature", type=float, default=0.2, help="Sampling temperature")
    parser.add_argument("--max_tokens", type=int, default=2000, help="Max tokens for completion")
    args = parser.parse_args()

    if not args.verilog_file.exists():
        print(f"Error: File not found: {args.verilog_file}", file=sys.stderr)
        sys.exit(1)

    rtl_text = args.verilog_file.read_text(encoding="utf-8", errors="ignore")

    # Initialize OpenAI client
    client = openai.OpenAI(api_key=args.api_key)

    # 1st attempt
    messages, dut_name = build_messages(rtl_text, args.verilog_file.name, args.extra)
    try:
        completion = call_openai(client, args.model, messages, args.temperature, args.max_tokens)
    except Exception as e:
        print(f"OpenAI API error: {e}", file=sys.stderr)
        sys.exit(2)

    if not completion.choices:
        print("No choices returned from API.", file=sys.stderr)
        sys.exit(3)

    content = completion.choices[0].message.content or ""
    verilog_tb = extract_verilog_only(content)

    # Validate, and if needed, retry once with stricter guidance
    if not looks_like_tb(verilog_tb, dut_name):
        messages.append({"role": "user", "content": RETRY_ADVICE.format(dut_name=dut_name)})
        try:
            retry_completion = call_openai(client, args.model, messages, 0.1, args.max_tokens)
            content = retry_completion.choices[0].message.content or ""
            verilog_tb = extract_verilog_only(content)
        except Exception as e:
            print(f"OpenAI API error on retry: {e}", file=sys.stderr)

    # Final safeguard: if still not code-like, inject a minimal compliant TB scaffold
    if not looks_like_tb(verilog_tb, dut_name):
        verilog_tb = textwrap.dedent(f"""\
        // Fallback scaffold because the model did not return a valid TB.
        module tb();
          initial begin
            $fsdbDumpfile("waves.fsdb");
            $fsdbDumpvars(0, tb);
            $display("Fallback scaffold: model did not return a proper testbench.");
            $finish;
          end
        endmodule
        """)

    # Strip any trailing non-code lines that might have slipped in
    # Keep everything up to the last 'endmodule'
    endmatch = list(re.finditer(r"\bendmodule\b", verilog_tb))
    if endmatch:
        verilog_tb = verilog_tb[:endmatch[-1].end()].strip()

    # Save to <stem>_tb.v
    stem = args.verilog_file.with_suffix("").name
    out_path = args.verilog_file.parent / f"{stem}_tb.v"
    out_path.write_text(verilog_tb, encoding="utf-8")

    print(f"Wrote testbench to: {out_path}")

if __name__ == "__main__":
    main()

