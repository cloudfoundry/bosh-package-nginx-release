import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
ARCHIVE = os.environ.get('NGINX_SOURCE_FIXTURE')
SIGNATURE = os.environ.get('NGINX_SIGNATURE_FIXTURE')
VERSION = os.environ.get('NGINX_FIXTURE_VERSION', '1.31.8')


@unittest.skipUnless(ARCHIVE and SIGNATURE, 'provide an official Nginx archive and detached signature fixture')
class SourceSignatureTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='nginx-source-signature-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.release = self.root / 'nginx-release'
        for name in ['keys', 'config', 'packages/nginx', 'blobs']:
            (self.release / name).mkdir(parents=True, exist_ok=True)
        shutil.copyfile(REPO / 'keys/nginx.gpg', self.release / 'keys/nginx.gpg')
        (self.release / 'blobs/nginx-1.0.0.tar.gz').write_bytes(b'previous fixture')
        self.source = self.root / 'nginx-src'
        self.source.mkdir()
        self.archive = self.source / ('nginx-' + VERSION + '.tar.gz')
        shutil.copyfile(ARCHIVE, self.archive)
        (self.source / 'version').write_text(VERSION)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.marker = self.root / 'bosh-operations'
        self.tool('curl', '#!/usr/bin/env python3\nimport os,shutil,sys\na=sys.argv;shutil.copyfile(os.environ["FIXTURE_SIGNATURE"],a[a.index("--output")+1])\n')
        self.tool('bosh', '#!/usr/bin/env bash\nprintf "%s\\n" "$*" >> "$FIXTURE_BOSH_OPERATIONS"\n')
        self.tool('git', '#!/usr/bin/env bash\nif [[ "$1" == status ]]; then printf " M fixture\\n"; fi\n')
        self.env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ['PATH'],
                        FIXTURE_SIGNATURE=SIGNATURE, FIXTURE_BOSH_OPERATIONS=str(self.marker),
                        PRIVATE_YML='fixture-private-config', GIT_USER_NAME='Fixture', GIT_USER_EMAIL='fixture@example.invalid')

    def tool(self, name, script):
        path = self.bin / name
        path.write_text(script)
        path.chmod(0o755)

    def run_task(self):
        return subprocess.run(['bash', str(REPO / 'ci/tasks/bump-versions.sh')], cwd=self.root,
                              env=self.env, capture_output=True, text=True)

    def test_valid_publisher_signature_allows_blob_update(self):
        result = self.run_task()
        self.assertEqual(result.returncode, 0, result.stderr)
        operations = self.marker.read_text().splitlines()
        self.assertEqual(operations[0], 'sync-blobs')
        self.assertIn('remove-blob nginx-1.0.0.tar.gz', operations)
        self.assertTrue(any(operation.startswith('add-blob ') for operation in operations))
        self.assertIn('upload-blobs', operations)

    def test_tampered_archive_rejected_before_blob_operations(self):
        self.archive.write_bytes(self.archive.read_bytes() + b'changed-bytes')
        self.assertNotEqual(self.run_task().returncode, 0)
        self.assertFalse(self.marker.exists())
        self.assertFalse((self.release / 'config/private.yml').exists())

    def test_unknown_signer_rejected_before_blob_operations(self):
        (self.release / 'keys/nginx.gpg').write_bytes(b'')
        self.assertNotEqual(self.run_task().returncode, 0)
        self.assertFalse(self.marker.exists())

    def test_mismatching_version_rejected(self):
        (self.source / 'version').write_text('0.0.99')
        self.assertNotEqual(self.run_task().returncode, 0)
        self.assertFalse(self.marker.exists())

    def test_multiple_archives_rejected(self):
        (self.source / 'nginx-0.0.99.tar.gz').write_bytes(b'additional fixture')
        self.assertNotEqual(self.run_task().returncode, 0)
        self.assertFalse(self.marker.exists())


if __name__ == '__main__':
    unittest.main()
