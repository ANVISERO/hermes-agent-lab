import importlib.util
import sys
import unittest
from pathlib import Path

scripts = Path(__file__).parents[1] / 'scripts'
sys.path.insert(0, str(scripts))
spec = importlib.util.spec_from_file_location('redaction', scripts / 'redact-evidence.py')
redaction = importlib.util.module_from_spec(spec)
spec.loader.exec_module(redaction)


class RedactionTest(unittest.TestCase):
    def test_known_secret_including_partial_overlaps(self):
        result = redaction.redact('long-test-secret and test-secret', ['test-secret', 'long-test-secret'])
        self.assertNotIn('test-secret', result)

    def test_token_patterns_without_env_entry(self):
        text = 'url/bot123456789:abcdefghijklmnopqrstuvwxyz_12345678/getMe sk-or-v1-fakevalue'
        result = redaction.redact(text, [])
        self.assertNotIn('abcdefghijklmnopqrstuvwxyz', result)
        self.assertNotIn('sk-or-v1-', result)

    def test_keep_nonsecret_operational_evidence(self):
        text = 'restart=unless-stopped running=true boot_id=test-id'
        self.assertEqual(redaction.redact(text, ['']), text)


if __name__ == '__main__':
    unittest.main()
