#!/usr/bin/env python3
"""Fail closed on the lab's Telegram dotenv policy, without printing credentials.

This is a preflight check, not a replacement for checking effective Hermes
configuration and trying a real unauthorized account.
"""
import argparse
import re
from pathlib import Path


def read_env(text):
    values = {}
    for number, raw in enumerate(text.splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        if line.startswith('export '):
            line = line[7:].lstrip()
        key, separator, value = line.partition('=')
        key, value = key.strip(), value.strip()
        if not separator or not re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*', key):
            raise ValueError(f'Invalid dotenv syntax at line {number}')
        if key in values:
            raise ValueError(f'Duplicate dotenv key: {key}')
        if value.startswith(('"', "'")):
            quote = value[0]
            end = value.find(quote, 1)
            if end < 0 or (value[end + 1:].strip() and not value[end + 1:].strip().startswith('#')):
                raise ValueError(f'Unsupported quoted dotenv value at line {number}')
            value = value[1:end]
        else:
            value = re.split(r'\s+#', value, maxsplit=1)[0].rstrip()
        values[key] = value
    return values


def validate(values, chat_id=None):
    owner = values.get('TELEGRAM_ALLOWED_USERS', '')
    if not re.fullmatch(r'[1-9][0-9]*', owner):
        raise ValueError('TELEGRAM_ALLOWED_USERS must contain exactly one numeric owner ID')
    for key in ('TELEGRAM_BOT_TOKEN', 'OPENROUTER_API_KEY'):
        value = values.get(key, '')
        if not value or any(marker in value.lower() for marker in ('replace', 'your_', 'example')):
            raise ValueError(f'{key} is missing or still a placeholder')
    for key, value in values.items():
        if (key.startswith(('TELEGRAM_', 'GATEWAY_')) and 'ALLOW_ALL' in key
                and value.lower() not in ('', '0', 'false', 'no', 'off')):
            raise ValueError(f'{key} must be disabled')
        if key.startswith('TELEGRAM_') and ('ALLOWED' in key or 'ALLOWLIST' in key) and '*' in value:
            raise ValueError(f'Wildcard access is forbidden: {key}')
    for key in ('TELEGRAM_GROUP_ALLOWED_USERS', 'TELEGRAM_GROUP_ALLOWED_CHATS'):
        if values.get(key):
            raise ValueError(f'{key} must be empty for this private lab bot')
    if chat_id is not None and chat_id != owner:
        raise ValueError('Cron chat ID must match the allowlisted owner ID')
    return owner


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('env_file', type=Path)
    parser.add_argument('--chat-id')
    args = parser.parse_args()
    try:
        validate(read_env(args.env_file.read_text()), args.chat_id)
    except (OSError, ValueError) as error:
        parser.exit(1, f'FAIL: {error}\n')
    print('PASS: explicit single-owner Telegram dotenv policy; no tokens displayed')


if __name__ == '__main__':
    main()
