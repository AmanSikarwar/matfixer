import 'package:matfixer/models/guide_model.dart';

final List<InstallationStep> installationSteps = [
  InstallationStep(
    title: "Step 1: Open t4.m",
    content: "Open the MATLAB file named `t4.m` using MATLAB or any code editor.",
    language: "text",
    code: """try


%%%%%%%%%%%%%%%%%%% write code here 



catch ME
    % Handle the error and send the code inside try as a prompt via POST
    disp(['An error occurred: ', ME.message]);

    % Prepare POST request to send the prompt
    serverURL = 'http://172.18.40.104:8001/generate'; % Replace with your desired server URL
    options = weboptions('Timeout', 10, 'MediaType', 'application/json');

    % Extract code as cell array
    promptLines = { ...
        'myArray = [10, 20, 30];', ...
        'value = myArray(4);', ...
        'disp([''Value: '', num2str(value)]);', ...
    };
    promptCode = strjoin(promptLines, '\n');

    % Create JSON body
    requestBody = struct('prompt', promptCode);

    try
        % Send POST request
        response = webwrite(serverURL, requestBody, options);
        disp(response);

        new_content = response.new_content;

        % Save to temporary file
        temp_input_file = 'temp_input.txt';
        fid = fopen(temp_input_file, 'w');
        fprintf(fid, '%s', new_content);
        fclose(fid);

        % Call Python script
        python_file = 'smart_write.py';
        command = sprintf('python3 "%s" "%s"', python_file, temp_input_file);
        status = system(command);

        if status == 0
            disp('Python script ran successfully.');
        else
            disp('Python script failed to run.');
        end

    catch ServerError
        disp(['Error sending POST request: ', ServerError.message]);
    end
end
""",
  ),
  InstallationStep(
    title: "Step 2: Write Your Code in the Try Section",
    content: "Insert your MATLAB code inside the try block where the comment says:",
    code: """try

A = [1, 2, 3; 4, 5, 6];
B = [7, 8];

C = A + B;  % This will cause an error


catch ME
    % Handle the error and send the code inside try as a prompt via POST
    disp(['An error occurred: ', ME.message]);

    % Prepare POST request to send the prompt
    serverURL = 'http://172.18.40.104:8001/generate'; % Replace with your desired server URL
    options = weboptions('Timeout', 10, 'MediaType', 'application/json');
"""
  ),
  InstallationStep(
    title: "Step 3: Move smart_write.py",
    content: "Move the `smart_write.py` file into the same directory that contains `t4.m`.",
    language: "bash",
    code: """import sys
import os
import json

# Ensure a file path is passed
if len(sys.argv) > 1:
    input_file = sys.argv[1]
    with open(input_file, 'r') as f:
        content = f.read()
else:
    print("No input file provided.")
    sys.exit(1)

# Remove markdown fences and extract sources
parts = content.split('```')
if len(parts) >= 3:
    matlab_block = parts[1]
    tail = parts[2]
else:
    matlab_block = content
    tail = ''

# Split and drop language tag if present
lines = matlab_block.splitlines()
if lines and lines[0].strip().lower() == 'matlab':
    lines = lines[1:]

# Extract sources
sources = ''
for ln in tail.splitlines():
    if ln.strip().lower().startswith('sources:'):
        sources = ln.strip()[len('Sources:'):].strip()
        break

# Prepare code lines
code_lines = [ln.rstrip() for ln in lines if ln.strip()]

# Write MATLAB script with proper quoting
target_mat_file = "t4.m" ####give matlab file name








with open(target_mat_file, 'w') as mat_file:
    # try block
    mat_file.write('try\n')
    if sources:
        mat_file.write(f"    % Sources: {sources}\n")
    for ln in code_lines:
        mat_file.write(f"    {ln}\n")
    # 20 blank lines
    mat_file.write('\n' * 20)
    # catch block
    mat_file.write('catch ME\n')
    mat_file.write('    % Handle the error and send the code inside try as a prompt via POST\n')
    mat_file.write("    disp(['An error occurred: ', ME.message]);\n\n")
    mat_file.write("    % Prepare POST request to send the prompt\n")
    mat_file.write("    serverURL = 'http://172.18.40.104:8001/generate'; % Replace with your desired server URL\n")
    mat_file.write("    options = weboptions('Timeout', 10, 'MediaType', 'application/json');\n\n")
    # Build promptLines for strjoin
    mat_file.write('    % Extract code as cell array\n')
    mat_file.write('    promptLines = { ...\n')
    for ln in code_lines:
        esc = ln.replace("'", "''")
        mat_file.write(f"        '{esc}', ...\n")
    mat_file.write('    };\n')
    mat_file.write("    promptCode = strjoin(promptLines, '\\n');\n\n")
    mat_file.write('    % Create JSON body\n')
    mat_file.write("    requestBody = struct('prompt', promptCode);\n\n")
    mat_file.write('    try\n')
    mat_file.write('        % Send POST request\n')
    mat_file.write('        response = webwrite(serverURL, requestBody, options);\n')
    mat_file.write('        disp(response);\n\n')
    mat_file.write('        new_content = response.new_content;\n\n')
    mat_file.write('        % Save to temporary file\n')
    mat_file.write("        temp_input_file = 'temp_input.txt';\n")
    mat_file.write("        fid = fopen(temp_input_file, 'w');\n")
    # Correct fprintf quoting
    mat_file.write("        fprintf(fid, '%s', new_content);\n")
    mat_file.write('        fclose(fid);\n\n')
    mat_file.write('        % Call Python script\n')
    mat_file.write("        python_file = 'smart_write.py';\n")
    # Escape quotes in Python string for MATLAB command line
    mat_file.write("        command = sprintf('python3 \"%s\" \"%s\"', python_file, temp_input_file);\n")
    mat_file.write('        status = system(command);\n\n')
    mat_file.write('        if status == 0\n')
    mat_file.write("            disp('Python script ran successfully.');\n")
    mat_file.write('        else\n')
    mat_file.write("            disp('Python script failed to run.');\n")
    mat_file.write('        end\n\n')
    mat_file.write('    catch ServerError\n')
    mat_file.write("        disp(['Error sending POST request: ', ServerError.message]);\n")
    mat_file.write('    end\n')
    mat_file.write('end\n')

print(f"Generated MATLAB script at {target_mat_file}")
""",
  ),
  InstallationStep(
    title: "Step 4: Run t4.m in MATLAB",
    content: "Run `t4.m` inside MATLAB. If your code throws an error, it will automatically send the code to the server and execute `smart_write.py`.",
    language: "matlab",
    code: "run('t4.m');",
  ),
];
