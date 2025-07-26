#!/bin/python

import sys
import time
import threading
import os
# import requests  # New import for HTTP request
import urllib3
import json
google_api_key = os.getenv("GOOGLE_API_KEY")

translation_done = False

def unescape(s):
    s = s.replace("\\n", "\n")
    s = s.replace("\\t", "\t")
    s = s.replace("\\r", "\r")
    s = s.replace("\\'", "'")
    s = s.replace('\\"', '"')
    s = s.replace("\\\\", "\\")
    return s


class BashTranslator:
    def __init__(self) -> None:
        self.bash_script = None
        self.messages = [
            {
                "role": "system",
                "content": "You are a helpful assistant that translates natural language instructions into bash scripts. Include bash command only"

            {
                "role": "user",
                "content": "command: Create a tar archive of the 'project' directory and compress it using gzip\n"
            },
            {
                "role": "assistant",
                "content": "tar -czvf project.tar.gz project"
            },
            {
                "role": "user",
                "content": "command: Find all .txt files in the current directory and subdirectories and delete them\n"
            },
            {
                "role": "assistant",
                "content": "find . -name '*.txt' -type f -delete"
            },
        ]
        self.translation_done = False

    def print_animation(self):
        moon_phases = [
            "🌑 ", "🌒 ", "🌓 ", "🌔 ", "🌕 ", "🌖 ", "🌗 ", "🌘 "
        ]
        while not self.translation_done:  # Infinite loop to keep the animation running
            for phase in moon_phases:
                print(f'\r\t Now thinking {phase} ...', end=' ', flush=True)
                time.sleep(0.1)  # Adjust the speed of the animation

    def translate_to_bash(self, natural_language_input):
        new_message = {
            "role": "user",
            "content": f"command:{natural_language_input}\n"
        }
        self.messages.append(new_message)
        few_shot_examples = """
Translate the natural language instruction into a bash command, don't include the triple quote '```'

command: Create a tar archive of the 'project' directory and compress it using gzip
tar -czvf project.tar.gz project

command: Find all .txt files in the current directory and subdirectories and delete them
find . -name '*.txt' -type f -delete
"""

        # Create the full prompt using the few-shot examples and the user's input
        full_prompt = f"""
{few_shot_examples}

command: {natural_language_input}
"""

        # Construct the request for Gemini API
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={google_api_key}"
        headers = {
            'Content-Type': 'application/json'
        }
        data = {
            "contents": [
                {
                    "parts": [{"text": full_prompt}]
                }
            ]
        }
        #print(full_prompt)

        # Send the HTTP request to Gemini API
        http = urllib3.PoolManager()
        data_bytes = json.dumps(data).encode('utf-8')
        response = http.request('POST', url, body=data_bytes, headers=headers)
        # response = requests.post(url, headers=headers, data=json.dumps(data))

        # Handle the response
        if response.status == 200:
            # Extract the translated bash script from the response
            #print(response.json())
            response_json = json.loads(response.data.decode("utf-8"))
            self.bash_script = response_json['candidates'][0]['content']['parts'][0]['text']
            self.messages.append(
                {"role": "assistant", "content": self.bash_script}
            )
        else:
            print(f"Error: {response.status} ")
            self.bash_script = "An error occurred during translation."
            exit(-1)

        self.translation_done = True
        return self.bash_script

    def parse_arguments(self):
        args = " ".join(sys.argv[1:])
        return args

    def main(self):
        natural_language_input = self.parse_arguments()

        translation_thread = threading.Thread(
            target=lambda x: self.translate_to_bash(x), args=(natural_language_input,))

        translation_thread.start()

        import tempfile
        import subprocess
        try:
            from pygments import highlight
            from pygments.lexers import BashLexer
            from pygments.formatters import TerminalFormatter
            _highlight = lambda x : highlight(x, BashLexer(), TerminalFormatter())
        except ImportError:
            _highlight = lambda x : x
        self.print_animation()
        translation_thread.join()

        sys.stdout.write("\r")
        sys.stdout.write("\033[K")

        print("This might be what you're looking for: ")

        print("``` bash")
        print(_highlight(self.bash_script))
        print("```")

        self.bash_script = f"#!/bin/bash \n{self.bash_script}"

        action = input("Would you like to store or execute the script? ([S]ave/[E]xecute/[V]im): ").strip().lower()
        if action[0] == "s":
            filename = input("Please enter the filename to save the script: ")
            with open(filename, 'w') as file:
                file.write(self.bash_script)
            print(f"Script saved to {filename}")
        elif action[0] == "v":
            filename = input("Please enter the filename to save the script: ")
            with open(filename, 'w') as file:
                file.write(self.bash_script)
            os.chmod(filename, 0o755)
            subprocess.call(['vim', filename])
            subprocess.call([filename])
        elif action[0] == "e":
            temp_file_name = tempfile.mktemp()
            try:
                with open(temp_file_name, "w") as temp_file:
                    temp_file.write(self.bash_script)
                os.chmod(temp_file_name, 0o755)
                subprocess.call([temp_file_name])
            finally:
                os.unlink(temp_file_name)
        else:
            print("Invalid option. Exiting.")


if __name__ == "__main__":
    bash_translator = BashTranslator()
    bash_translator.main()

