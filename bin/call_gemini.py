#!/bin/python

import argparse
import json
import os
import sys
import threading
import time
import urllib.error
import urllib.request

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
if not GOOGLE_API_KEY:
    # get it from .env
    dotenv = os.path.expanduser("~/dotfiles/bin/.env")
    with open(dotenv, "r") as f:
        for line in f:
            if line.startswith("GOOGLE_API_KEY="):
                GOOGLE_API_KEY = line.strip().split("=", 1)[1]
                break
if not GOOGLE_API_KEY:
    print("GOOGLE_API_KEY is not set", file=sys.stderr)
    sys.exit(1)


def error(message: str) -> None:
    print(f"Error: {message}", file=sys.stderr)
    sys.exit(1)


def spinner(stop_event: threading.Event) -> None:
    phases = ["🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘"]
    while not stop_event.is_set():
        for phase in phases:
            if stop_event.is_set():
                break
            print(f"\r\tThinking {phase}...", end="", flush=True)
            time.sleep(0.1)
    # clear line
    print("\r\t                      ")


def call_gemini(model, messages, verbose=False) -> str:
    if isinstance(messages, str):
        try:
            messages = json.loads(messages)
        except json.JSONDecodeError as err:
            error(f"Invalid JSON payload: {err}")
    if not isinstance(messages, list):
        error("JSON payload must be a list of messages")

    contents = []
    for message in messages:
        if not isinstance(message, dict):
            error("Each message must be a dict")
        content = message.get("content")
        if not isinstance(content, str):
            error("Each message must have a 'content' field of type string")
        role = message.get("role", "user")
        if role not in ["user", "system", "assistant"]:
            error("Message 'role' must be one of 'user', 'system', or 'assistant'")
        if role == "assistant":
            role = "model"
        if role == "system":
            role = "user"
        contents.append({"parts": [{"text": content}], "role": role})

    url = (
        f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?"
        f"key={GOOGLE_API_KEY}"
    )
    headers = {"Content-Type": "application/json"}
    payload = {"contents": contents}
    request = urllib.request.Request(
        url, data=json.dumps(payload).encode("utf-8"), headers=headers, method="POST"
    )
    if verbose:
        print("=== Gemini request ===", file=sys.stderr)
        print(json.dumps(payload, indent=2), file=sys.stderr)
    try:
        with urllib.request.urlopen(request) as response:
            if response.getcode() != 200:
                error(
                    f"Unexpected status: {response.getcode()}\n{response.read().decode('utf-8')}"
                )
            response_data = response.read().decode("utf-8")
    except urllib.error.HTTPError as err:
        response_body = err.read().decode("utf-8", errors="ignore")
        if response_body:
            error(f"HTTP error: {err.code} {err.reason}\n{response_body}")
        error(f"HTTP error: {err.code} {err.reason}")
    except urllib.error.URLError as err:
        error(f"Network error: {err.reason}")
    response_json = json.loads(response_data)
    if verbose:
        print("=== Gemini response ===", file=sys.stderr)
        print(json.dumps(response_json, indent=2), file=sys.stderr)
    return response_json["candidates"][0]["content"]["parts"][0]["text"].strip()

def call_gemini_with_spinner(model, messages, spinner_enabled=True, verbose=False) -> str:
    if not spinner_enabled:
        return call_gemini(model, messages, verbose)
    stop_event = threading.Event()
    thread = threading.Thread(target=spinner, args=(stop_event,))
    thread.start()
    try:
        result = call_gemini(model, messages, verbose)
    finally:
        stop_event.set()
        thread.join()
    return result


def git_commit_message(model, git_changes, use_spinner=True, verbose=False) -> str:
    prompt = [
        {
            "role": "user",
            "content": f"Generate a concise and descriptive git commit message. "
            + "Include at most 20 words. Talk about at most 3 key changes. Use imperative mood. "
            + "changes:\n\n"
            + git_changes,
        },
    ]
    return call_gemini_with_spinner(model, prompt, use_spinner, verbose)


def bash_translation(model, natural_language_command, use_spinner=True, verbose=False) -> str:
    prompt = [
        {"role": "user", "content": "You are an expert at translating natural language to bash commands. Provide only the bash command without any explanation. Don't include '```bash' or any other formatting."},
        {
            "role": "user",
            "content": f"Compress the following directory into a tar.gz file: photos",
        },
        {
            "role": "assistant",
            "content": "tar -czvf photos.tar.gz photos",
        },
        {
            "role": "user",
            "content": f"List all files in the current directory, including hidden files, in long format.",
        },
        {
            "role": "assistant",
            "content": "ls -la",
        },
        {
            "role": "user",
            "content": f"Translate the following natural language command into a bash command:\n\n{natural_language_command}",
        },
    ]
    result = call_gemini_with_spinner(model, prompt, use_spinner, verbose)
    return result


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Call Gemini via Copilot engine")
    parser.add_argument("-S", "--no-spinner", action="store_true", help="Disable spinner display")
    parser.add_argument("-m", "--model", default="gemini-2.5-flash-lite", help="Gemini model to use")
    parser.add_argument("-j", "--json", help="JSON payload to send (as string)")
    parser.add_argument("-f", "--json-file", dest="json_file", help="Read JSON payload from a file")
    parser.add_argument("--git_message", help="Generate a git commit message for provided diff summary")
    parser.add_argument("-v", "--verbose", action="store_true", help="Print request and response payloads")
    parser.add_argument("instruction", nargs="*", help="Natural language command for bash translation")
    return parser.parse_args()


def read_json_file(args: argparse.Namespace) -> str:
    if args.json_file:
        try:
            with open(args.json_file, "r") as handle:
                return handle.read().strip()
        except OSError as err:
            error(f"Unable to read JSON file: {err}")
    return args.json


def main() -> None:
    args = parse_args()
    args.json = read_json_file(args)
    spinner_enabled = not args.no_spinner
    verbose_enabled = args.verbose
    if args.git_message:
        result = git_commit_message(args.model, args.git_message, spinner_enabled, verbose_enabled)
        print(result)
        return
    if args.instruction:
        instruction = " ".join(args.instruction or []).strip()
        result = bash_translation(args.model, instruction, spinner_enabled, verbose_enabled)
        print(result)
    if args.json:
        result = call_gemini_with_spinner(args.model, args.json, spinner_enabled, verbose_enabled)
        print(result)
        return


if __name__ == "__main__":
    main()

    
