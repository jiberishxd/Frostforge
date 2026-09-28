"""Exercise the installable namespace and paths, including its real Lua loader."""
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from package import CLIENTS, payload

LUA = shutil.which("lua5.1") or str(ROOT / ".tools/lua-5.1.5/src/lua")


class PackagingTests(unittest.TestCase):
    def test_github_source_folder_matches_the_installable_addon(self):
        self.assertTrue((ROOT / "Frostforge/Frostforge.toc").is_file())
        self.assertFalse((ROOT / "JiberishUI").exists())
        for name, data in payload("Retail").items():
            if name.endswith(".lua") and name != "Frostforge/Build.lua":
                self.assertEqual((ROOT / name).read_bytes(), data)

    def test_one_frostforge_folder_with_resolvable_manifest_and_media(self):
        for client, (interface, _, _) in CLIENTS.items():
            with self.subTest(client=client):
                files = payload(client)
                self.assertEqual({p.split("/")[0] for p in files}, {"Frostforge"})
                toc = files["Frostforge/Frostforge.toc"].decode()
                self.assertIn(f"## Interface: {interface}\n", toc)
                self.assertIn("## SavedVariables: JiberishUIDB\n", toc)
                self.assertIn("## SavedVariablesPerCharacter: JiberishUICharacterDB\n", toc)
                self.assertNotIn("Frostforge/JiberishUI.toc", files)
                for line in toc.splitlines():
                    if line.endswith(".lua"):
                        self.assertIn("Frostforge/" + line.replace("\\", "/"), files)
                paths = set()
                for name, data in files.items():
                    if name.endswith((".lua", ".toc")):
                        code = data.decode().replace("\\\\", "/").replace("\\", "/")
                        paths.update(re.findall(r'Interface/AddOns/([^"\s]+)', code))
                self.assertEqual(len(paths), 296)
                for path in paths:
                    self.assertIn(path, files)
                    self.assertTrue(path.startswith("Frostforge/"))

    @unittest.skipUnless(Path(LUA).is_file(), "Lua 5.1 is required for package startup checks")
    def test_relocated_runtime_loads_and_preserves_copied_profiles(self):
        for client, (interface, _, _) in CLIENTS.items():
            with self.subTest(client=client), tempfile.TemporaryDirectory(prefix="frostforge-install-") as temp:
                for name, data in payload(client).items():
                    if name.endswith((".lua", ".toc")):
                        path = Path(temp) / name
                        path.parent.mkdir(parents=True, exist_ok=True)
                        path.write_bytes(data)
                result = subprocess.run(
                    [LUA, "tests/package_install.lua", str(Path(temp) / "Frostforge"), str(interface)],
                    cwd=ROOT, capture_output=True, text=True, check=False,
                )
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
