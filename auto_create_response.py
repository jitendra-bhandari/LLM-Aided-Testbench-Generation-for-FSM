#!./venv/bin/python3
import subprocess
import languagemodels as lm
import conversation as cv

import sys
import os
import getopt
import time
import re


def extract_errors_from_log(file_path):
    # Reading the content of the log file
    with open(file_path, 'r') as file:
        log_content = file.read()

    # Updated regular expression to stop after the caret symbol or a similar clear delimiter
    error_pattern = re.compile(r"(Error\-\[.*?^\s*?\n)", re.DOTALL | re.MULTILINE)

    warning_pattern = re.compile(r"(Warning\-\[.*?^\s*?\n)", re.DOTALL | re.MULTILINE)
    # Extracting all errors using the defined pattern
    errors = error_pattern.findall(log_content)

    warnings = warning_pattern.findall(log_content)

    warnings_to_exclude = ["LCA_FEATURES_ENABLED"]
    filtered_warnings = [warning for warning in warnings if not any(exclusion in warning for exclusion in warnings_to_exclude)]

    return errors, filtered_warnings



def find_verilog_modules(markdown_string, module_name='tb'):

    module_pattern1 = r'\bmodule\b\s+\w+\s*\([^)]*\)\s*;.*?endmodule\b'

    module_pattern2 = r'\bmodule\b\s+\w+\s*#\s*\([^)]*\)\s*\([^)]*\)\s*;.*?endmodule\b'

    module_matches1 = re.findall(module_pattern1, markdown_string, re.DOTALL)

    module_matches2 = re.findall(module_pattern2, markdown_string, re.DOTALL)

    module_matches = module_matches1 + module_matches2

    if not module_matches:
        return []

    return module_matches

#def find_verilog_modules(markdown_string,module_name='top_module'):
#    print(markdown_string)
#    # This pattern captures module definitions
#    module_pattern = r'\bmodule\b\s+\w+\s*\(.*?\)\s*;.*?endmodule\b'
#    # Find all the matched module blocks
#    module_matches = re.findall(module_pattern, markdown_string, re.DOTALL)
#    # If no module blocks found, return an empty list
#    if not module_matches:
#        return []
#    return module_matches

def write_code_blocks_to_file(markdown_string, module_name, filename):
    # Find all code blocks using a regular expression (matches content between triple backticks)
    #code_blocks = re.findall(r'```(?:\w*\n)?(.*?)```', markdown_string, re.DOTALL)
    code_match = find_verilog_modules(markdown_string, module_name)

    if not code_match:
        print("No code blocks found in response")
        exit(3)

    #print("----------------------")
    #print(code_match)
    #print("----------------------")
    # Open the specified file to write the code blocks
    with open(filename, 'w') as file:
        for code_block in code_match:
            file.write(code_block)
            file.write('\n')




def extract_info_from_file(filename):
    with open(filename, 'r') as file:
        lines = file.readlines()

    # Variable to store the extracted float value for the transition percentage
    transition_percent = None
    # List to store the modified lines (1st and 3rd column from state transitions)
    modified_lines = []

    # Flag to control capturing lines only during relevant sections
    capture_transitions = False

    for line in lines:
        # Extracting the transition percent from the specific line
        if "Transitions" in line and transition_percent is None:  # Ensure it's captured only once
            parts = line.split()
            if parts:
                percent_str = parts[-1]  # Assuming the percent value is always the last item
                try:
                    transition_percent = float(percent_str.strip('%'))
                except ValueError:
                    print("Error: Could not convert the percent value to float.")
                    continue

        # Check if the line marks the beginning of transition details
        if 'State, Transition and Sequence Details' in line:
            capture_transitions = True

        # Check if the line marks the end of detailed section
        elif 'Branch Coverage for Module' in line:
            capture_transitions = False

        # Capturing and modifying state transition lines within the designated section
        if capture_transitions and '->' in line:
            parts = line.split()
            if len(parts) >= 3:
                transition = parts[0]
                status = parts[2:]
                modified_lines.append(f"{transition} {status}")

    return transition_percent, modified_lines




def extract_module_content(log_contents):
    # Find the start index of the module keyword
    start_index = log_contents.find("module tb();")
    if start_index == -1:
        return "No module found"
    
    # Find the end index of the endmodule keyword, or use the end of the file
    end_index = log_contents.find("endmodule", start_index)
    if end_index == -1:
        end_index = len(log_contents)
    else:
        end_index += len("endmodule")  # Include the keyword 'endmodule' if needed
    
    # Extract the contents between 'module' and 'endmodule'
    return log_contents[start_index:end_index]


def generate_verilog(conv, model_type, model_id=""):
    if model_type == "ChatGPT4":
        model = lm.ChatGPT4()
    elif model_type == "Claude":
        model = lm.Claude()
    elif model_type == "ChatGPT3p5":
        model = lm.ChatGPT3p5()
    elif model_type == "PaLM":
        model = lm.PaLM()
    elif model_type == "CodeLLama":
        model = lm.CodeLlama(model_id)

    return(model.generate(conv))


def verilog_loop(design_prompt,  model_type, outdir="", log=None):

    if outdir != "":
        outdir = outdir + "/"

    conv = cv.Conversation(log_file=log)


    conv.add_message("system", "You are an expert in design verification for Verilog code. \
                    Given a Verilog RTL module, you will write a testbench to simulate it and try to cover all the possible state transitions. \
                    Please follow the below instruction while providing any response: \
                    1. You will not add any timescale command. \
                    2. The testbench should start with: module tb();  \
                    3. You will add $fsdbDumpfile, $fsdbDumpvars commands in the tesbench  at the starting of first intital block. \
                    4. Please use  apply_input() format to apply input sequences.\
                    5. You should pay attention whether it requires active or high  reset from the RTL code provided. \
                    4. Also at the end of test patterns add $finish. \
                    ")
    

    conv.add_message("user", design_prompt)

    success = False
    timeout = False
    compiled = False
    iterations = 0
    iterations_fsm = 0
    #filename = os.path.join(outdir,"tb.v")

    print("Loop entered")
   
    while not (success or timeout):

        print("Iterations: " + str(iterations))
        print("Iterations_FSM: " + str(iterations_fsm))
        # Generate a response
        response = generate_verilog(conv, model_type)
        conv.add_message("assistant", response)

        #text = extract_module_content(response)
        #with open('tb.v', 'w') as file:
        #    file.write(text)
        write_code_blocks_to_file(response, 'tb', 'tb.v')
        #os.system('./run.sh')
        # Start the script
        process = subprocess.Popen(['./run.sh'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        # Specify the timeout in seconds
        wait = 100  # For example, 10 seconds

        try:
            process.wait(timeout=wait)
        except subprocess.TimeoutExpired:
            print("The script did not complete in time, moving on...")
            # Optionally, terminate the process if it's not finished
            process.terminate()

        file_path = 'vcs.log'  # Replace 'path_to_your_log_file.log' with your actual log file path
        extracted_errors, extracted_warnings = extract_errors_from_log(file_path)
       
        #print(extracted_errors)
        #print(extracted_warnings)


        compiled = False
        if extracted_errors:
            status = "Error compiling testbench"
            #print(status)

            message = "The testbench failed to compile. Please fix the testbench code. The output of VCS is as follows:\n"+ str(extracted_errors)
        elif  extracted_warnings:
            status = "Warnings compiling testbench"
            #print(status)
            message = "The testbench compiled with warnings. Please fix the testbench code. The output of VCS is as follows:\n"+ str(extracted_warnings)
        else:
            compiled = True
        
   
        #print(compiled)

        if not compiled:

            conv.add_message("user", message)
            iterations += 1

        if iterations >= 5:
            timeout = True

        success = False

        if compiled:

            iterations = 0
            file_path = 'urgReport/modinfo.txt'
            transition_percent, modified_lines = extract_info_from_file(file_path)

            # Printing the results
            print("Extracted Transitions Percent:", transition_percent)
            #print("Modified state transition lines:")
            #for line in modified_lines:
            #    print(line)

            if float(transition_percent) >= 90:
                status = "Target Achieved"
                success = True
            elif iterations_fsm >= 10:
                status = "Iterations Timeout"
                timeout = True
            else:
                status = "Transitions not yet fully covered"
                message = "The current testbench doesn't cover all the transitions. Please write a testbench that cover each transitions possible using RTL code provided as reference. Always improve the testbench obtained in previous iteration with more additional testcase, do not delete any testcases from the testbench. If required reset to cover certain transitions. This is the RTL code:\n" + design_prompt + "\n\n" + "This is the list of transitions not covered yet:\n" + str(modified_lines)
                conv.add_message("user", message)
                iterations_fsm += 1


        with open(os.path.join(outdir,"log_iter_"+str(iterations)+".txt"), 'w') as file:
            file.write('\n'.join(str(i) for i in conv.get_messages()))
            file.write('\n\n Iteration status: ' + status + '\n')


    print("Loop exited")
    #print(success)
    #print(timeout)



def main():
    usage = "Usage: auto_create_verilog.py [--help] --prompt=<prompt>  --model=<llm model> --model_id=<model id> --log=<log file>\n\n\t-h|--help: Prints this usage message\n\n\t-p|--prompt: The initial design prompt for the Verilog module\n\n\t-m|--model: The LLM to use for this generation. Must be one of the following\n\t\t- ChatGPT3p5\n\t\t- ChatGPT4\n\t\t- Claude\n\n\t- CodeLLama\n\n\t-l|--log: [Optional] Log the output of the model to the given file"

    try:
        opts, args = getopt.getopt(sys.argv[1:], "hp:n:t:i:m:l", ["help", "prompt=", "model=", "model_id=","log="])
    except getopt.GetoptError as err:
        print(err)
        print(usage)
        sys.exit(2)


    # Default values
    max_iterations = 10

    for opt, arg in opts:
        if opt in ("-h", "--help"):
            print(usage)
            sys.exit()
        elif opt in ("-p", "--prompt"):
            prompt = arg
        elif opt in ("-m", "--model"):
            model = arg
        elif opt in ("-id", "--model_id"):
            model = arg
        elif opt in ("-o", "--outdir"):
            outdir = arg
        elif opt in ("-l", "--log"):
            log = arg


    # Check if prompt and module are set
    try:
        prompt
    except NameError:
        print("Prompt not set")
        print(usage)
        sys.exit(2)

    try:
        model
    except NameError:
        print("LLM not set")
        print(usage)
        sys.exit(2)

    try:
        outdir
    except NameError:
        outdir = ""

    if outdir != "":
        if not os.path.exists(outdir):
            os.makedirs(outdir)

    verilog_loop(prompt, model, outdir, log)

if __name__ == "__main__":
    main()
