import importlib.util
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location('check_access', Path(__file__).parents[1] / 'scripts/check_access.py')
access = importlib.util.module_from_spec(spec)
spec.loader.exec_module(access)


class AccessPolicyTest(unittest.TestCase):
    def base(self):
        return {'TELEGRAM_ALLOWED_USERS': '123456789',
                'TELEGRAM_BOT_TOKEN': 'test-token-value',
                'OPENROUTER_API_KEY': 'test-key-value'}

    def test_owner_private_chat(self):
        self.assertEqual(access.validate(self.base(), '123456789'), '123456789')

    def test_reject_empty_wildcard_and_multiple_owners(self):
        for owner in ('', '*', '123,*', '123,456', '${OWNER}', '123 456'):
            with self.subTest(owner=owner), self.assertRaises(ValueError):
                access.validate(dict(self.base(), TELEGRAM_ALLOWED_USERS=owner))

    def test_reject_group_or_allow_all_access(self):
        for key, value in (('TELEGRAM_GROUP_ALLOWED_CHATS', '-100123'),
                           ('TELEGRAM_ALLOW_ALL_USERS', 'true'),
                           ('GATEWAY_ALLOW_ALL_USERS', '1')):
            with self.subTest(key=key), self.assertRaises(ValueError):
                access.validate(dict(self.base(), **{key: value}))

    def test_reject_other_cron_recipient(self):
        with self.assertRaises(ValueError):
            access.validate(self.base(), '999999999')

    def test_no_duplicate_shadowing(self):
        with self.assertRaises(ValueError):
            access.read_env('TELEGRAM_ALLOWED_USERS=123\nTELEGRAM_ALLOWED_USERS=*\n')

    def test_quotes_comments_export(self):
        self.assertEqual(access.read_env('export OWNER="123" # owner\nURL=https://example.org/#anchor\n'),
                         {'OWNER': '123', 'URL': 'https://example.org/#anchor'})

    def test_malformed_value_not_leaked_in_error(self):
        secret = 'DO-NOT-PRINT-THIS-SECRET'
        with self.assertRaises(ValueError) as error:
            access.read_env('TOKEN="' + secret)
        self.assertNotIn(secret, str(error.exception))


if __name__ == '__main__':
    unittest.main()
