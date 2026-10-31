#!/usr/bin/env python3
"""Redact known credentials from text artifacts; private content needs manual review."""
import re
import sys
from pathlib import Path
from check_access import read_env


def redact(text, secrets):
    for secret in sorted(set(secrets), key=len, reverse=True):
        if len(secret) >= 6:
            text = text.replace(secret, '[REDACTED]')
    text = re.sub(r'(?<![0-9])[0-9]{6,}:[A-Za-z0-9_-]{20,}', '[REDACTED_TELEGRAM_TOKEN]', text)
    text = re.sub(r'\bsk-or-[A-Za-z0-9_-]+', '[REDACTED_OPENROUTER_KEY]', text)
    return text


def main():
    directory, env_file = map(Path, sys.argv[1:])
    values = read_env(env_file.read_text())
    secrets = [value for key, value in values.items()
               if any(part in key for part in ('TOKEN', 'KEY', 'SECRET', 'PASSWORD'))]
    for path in directory.iterdir():
        if path.is_file():
            path.write_text(redact(path.read_text(), secrets))


if __name__ == '__main__':
    main()
