#!/bin/bash

prompt_dir=`pwd`/prompts_new

output_dir=`pwd`/outputs

script=`pwd`/scripts/auto_create_response.py

source `pwd`/venv/bin/activate

tests_per_prompt=5

prompts=()

for path in "$prompt_dir"/*; do
	if [[ -f "$path" ]]; then
		prompt_name=$(basename "$path")
		prompts+=("${prompt_name%.*}")
	fi
done

echo $prompts
