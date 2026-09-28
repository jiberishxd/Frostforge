"""Publishing boundary tests: wrong builds never POST; preview never uses the API."""
import contextlib
import hashlib
import io
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import publish_curseforge as cf


class CurseForgeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.reports = []
        self.versions = []
        for number, (client, (interface, baseline, revision)) in enumerate(cf.CLIENTS.items(), 1):
            name = f'Jiberishs-Frostforge-{client}-{cf.VERSION}.zip'
            with zipfile.ZipFile(self.directory / name, 'w') as archive:
                archive.writestr('Frostforge/Frostforge.toc', f'## Interface: {interface}\n## Version: {cf.VERSION}\n')
            self.reports.append(dict(client=client, interface=interface, baseline=baseline,
                                     source_revision=revision, file=name, version=cf.VERSION,
                                     sha256=hashlib.sha256((self.directory / name).read_bytes()).hexdigest(),
                                     files=1, addon_folder='Frostforge'))
            self.versions.append(dict(id=number, gameVersionTypeID=cf.VERSION_TYPES[client],
                                      name=f'{interface // 10000}.{interface // 100 % 100}.{interface % 100}'))
        self.write_reports()
        self.event = dict(action='published', release=dict(tag_name=f'v{cf.VERSION}', draft=False,
                                                          prerelease=True, body='Frostforge update.'))

    def write_reports(self):
        (self.directory / 'packages.json').write_text(json.dumps(self.reports))

    def plan(self):
        return cf.package_plan(self.directory, list(cf.CLIENTS), self.event)

    def test_release_type_and_tag_match_the_addon(self):
        self.assertEqual(cf.release_metadata(self.event)[0], 'beta')
        self.event['release']['prerelease'] = False
        self.assertEqual(cf.release_metadata(self.event)[0], 'release')
        for field, value in [('tag_name', 'v9.9.9'), ('draft', True), ('body', ''), ('prerelease', None)]:
            with self.subTest(field=field):
                event = json.loads(json.dumps(self.event))
                event['release'][field] = value
                with self.assertRaises(ValueError):
                    cf.release_metadata(event)
        self.event['action'] = 'edited'
        with self.assertRaises(ValueError):
            cf.release_metadata(self.event)

    def test_only_explicit_supported_clients_are_accepted(self):
        self.assertEqual(cf.clients_from('Retail, Forever'), ['Retail', 'Forever'])
        for value in ['', 'Classic', 'Retail,Retail', 'Retail,', '../../outside']:
            with self.subTest(value=value), self.assertRaises(ValueError):
                cf.clients_from(value)

    def test_wrong_package_paths_versions_and_hashes_are_rejected(self):
        original = dict(self.reports[0])
        for field, value in [('file', '../private.zip'), ('version', '0.0.1'),
                             ('interface', 16001), ('sha256', 'bad'), ('files', 99)]:
            with self.subTest(field=field):
                self.reports[0] = dict(original, **{field: value})
                self.write_reports()
                with self.assertRaises(ValueError):
                    self.plan()

    def test_wrong_client_toc_is_rejected_even_with_valid_checksum(self):
        report = self.reports[0]
        path = self.directory / report['file']
        with zipfile.ZipFile(path, 'w') as archive:
            archive.writestr('Frostforge/Frostforge.toc', f'## Interface: 16001\n## Version: {cf.VERSION}\n')
        report['sha256'] = hashlib.sha256(path.read_bytes()).hexdigest()
        self.write_reports()
        with self.assertRaises(ValueError):
            self.plan()

    def test_version_resolution_uses_both_flavor_and_exact_version(self):
        plans = self.plan()
        wrong_flavor = dict(self.versions[0], id=99, gameVersionTypeID=123)
        cf.resolve_versions(plans, [wrong_flavor, *self.versions])
        self.assertEqual(plans[0]['metadata']['gameVersions'], [1])
        self.assertEqual(plans[1]['metadata']['gameVersions'], [2])
        for versions in [[], self.versions[:1], [*self.versions, self.versions[0]], {'error': 'bad'}]:
            with self.subTest(versions=versions), self.assertRaises(ValueError):
                cf.resolve_versions(self.plan(), versions)

    def test_all_clients_are_preflighted_before_any_post(self):
        calls = []
        def request(method, *args):
            calls.append(method)
            return self.versions[:1]
        with self.assertRaises(ValueError):
            cf.publish(self.plan(), self.directory, '1234', 'private-token', request)
        self.assertEqual(calls, ['GET'])

    def test_missing_credentials_stop_before_network(self):
        for project, token in [('', 'token'), ('../x', 'token'), ('0', 'token'), ('123', ''), ('123', 'bad\nheader')]:
            with self.subTest(project=project), self.assertRaises(ValueError):
                cf.publish(self.plan(), self.directory, project, token,
                           lambda *args: self.fail('No request should be made'))

    def test_upload_sends_exact_zip_metadata_and_records_ids(self):
        from email.parser import BytesParser
        calls = []
        def request(method, path, token, body=None, content_type=None):
            calls.append(method)
            self.assertEqual(token, 'private-token')
            if method == 'GET':
                self.assertEqual(path, '/api/game/wow/versions')
                return self.versions
            self.assertEqual(path, '/api/projects/1234/upload-file')
            message = BytesParser().parsebytes(f'Content-Type: {content_type}\r\nMIME-Version: 1.0\r\n\r\n'.encode() + body)
            parts = {p.get_param('name', header='content-disposition'): p for p in message.get_payload()}
            metadata = json.loads(parts['metadata'].get_payload(decode=True))
            self.assertEqual(metadata['releaseType'], 'beta')
            self.assertIn(metadata['gameVersions'], [[1], [2]])
            filename = parts['file'].get_filename()
            self.assertEqual(parts['file'].get_payload(decode=True), (self.directory / filename).read_bytes())
            return {'id': 100 + len(calls)}
        with contextlib.redirect_stdout(io.StringIO()):
            cf.publish(self.plan(), self.directory, '1234', 'private-token', request)
        receipts = (self.directory / 'curseforge-uploads.json').read_text()
        self.assertEqual([r['file_id'] for r in json.loads(receipts)], [102, 103])
        self.assertNotIn('private-token', receipts)
        self.assertEqual(calls, ['GET', 'POST', 'POST'])

    def test_partial_failure_keeps_receipt_without_retrying(self):
        calls = []
        def request(method, *args):
            calls.append(method)
            if method == 'GET':
                return self.versions
            if len(calls) == 2:
                return {'id': 9001}
            raise TimeoutError('connection lost')
        with contextlib.redirect_stdout(io.StringIO()), self.assertRaises(TimeoutError):
            cf.publish(self.plan(), self.directory, '1234', 'private-token', request)
        self.assertEqual(calls, ['GET', 'POST', 'POST'])
        receipts = json.loads((self.directory / 'curseforge-uploads.json').read_text())
        self.assertEqual(len(receipts), 1)
        self.assertEqual(receipts[0]['file_id'], 9001)

    def test_mutation_after_preflight_is_rejected(self):
        plan = self.plan()[0]
        (self.directory / plan['file']).write_bytes(b'changed')
        with self.assertRaises(ValueError):
            cf.multipart(plan, self.directory)

    def test_manual_preview_never_calls_publish_or_network(self):
        with patch.dict(os.environ, {}, clear=True), patch.object(cf, 'publish') as publish:
            with contextlib.redirect_stdout(io.StringIO()) as output:
                cf.main(['--dist', str(self.directory)])
            publish.assert_not_called()
            self.assertIn('preview', output.getvalue())
            with self.assertRaises(ValueError):
                cf.main(['--upload', '--dist', str(self.directory)])
            publish.assert_not_called()

    def test_http_errors_do_not_echo_secrets_or_follow_redirects(self):
        for status in [302, 401, 500]:
            with self.subTest(status=status), patch.object(cf.http.client, 'HTTPSConnection') as factory:
                connection = factory.return_value
                response = connection.getresponse.return_value
                response.status = status
                response.read.return_value = b'private-token was rejected'
                with self.assertRaises(ValueError) as error:
                    cf.request_json('GET', '/api/game/wow/versions', 'private-token')
                self.assertNotIn('private-token', str(error.exception))
                connection.request.assert_called_once()
                connection.close.assert_called_once()


if __name__ == '__main__':
    unittest.main()
