#!/bin/bash

prompt_dir=`pwd`/prompts_new

output_dir=`pwd`/outputs_chat3p5

script=`pwd`/scripts/auto_create_response.py

source `pwd`/venv/bin/activate

tests_per_prompt=1

promtps=()

for path in "$prompt_dir"/*; do
	if [[ -f "$path" ]]; then
		prompt_name=$(basename "$path")
		prompts+=("${prompt_name%.*}")
	fi
done

count=0

for prompt in "${prompts[@]}"; do
	#check if there's a matching testbench
        ((count++))
        echo "Test Prompt: $count"

	for ((i=0; i<tests_per_prompt; i++)); do
		mkdir -p $output_dir/$prompt/test_${i}
		cp $prompt_dir/${prompt}.v $output_dir/$prompt/test_${i}
		cp `pwd`/run.sh $output_dir/$prompt/test_${i}
		cd $output_dir/$prompt/test_${i}
               
	        echo "Test Prompt: $count Trial: ${i}"	
		python3 $script --prompt="$(cat $prompt_dir/${prompt}.v)"  --model=ChatGPT3p5 --log=${prompt}_log.txt		cd -
	done
done
