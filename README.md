# This is GitHub repo for our project on LLM Hardware Security.

## Setup:

### Prerequisites

- Python 3.6 or newer
- `pip` for installing dependencies

### Installation

1.  Clone the repository to your local machine:
```sh
git clone https://github.com/jitendra-bhandari/LLM-Aided-Testbench-Generation-for-FSM.git 
cd LLM-Aided-Testbench-Generation-for-FSM
```
2.  Set up a virtual environment (optional but recommended):
```sh
python3 -m venv venv
source venv/bin/activate
```
3.  Install the required python packages:
```sh
pip3 install -r requirements.txt
pip3 install -r requirements_new.txt
```

### Environment Variables
API Keys (Must be set for the models being used):
 - OpenAI API Key: `OPENAI_API_KEY` 
 - Anthropic API Key: `ANTHROPIC_API_KEY`
 - PaLM API Key: `PALM_API_KEY`

## Usage
To use the tool, follow the steps below:

1. Prepare your initial Verilog design prompt.

2. Run the tool with the necessary arguments:
```sh
./auto_create_verilog.py [--help] --prompt=<prompt>  --model=<llm model> --model_id=<model id> --log=<log file>
```
### Arguments
 - `-h|--help`: Prints this usage message
 - `-p|--prompt`: The initial design prompt for the Verilog module
 - `-m|--model`: The LLM to use for Verilog generation. Must be one of the following:
    - ChatGPT3p5
    - ChatGPT4
    - Claude
    - PaLM
    - CodeLLama
 - `-id|--model_id`: [Optional] for model other than CodeLLama, for codellama, model id is the huggingface repository to codellama
 - `-o|--outdir`: [Optional] Directory to output files to
 - `-l|--log`: [Optional] File to log the outputs of the model

![Sample Image](./table1.JPG)
![Sample Image](./rest_50.jpg)

