import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'tools'))
from recover_profiles import SavedData, export


class RecoveryTests(unittest.TestCase):
    def test_saved_settings_and_empty_tables(self):
        db = SavedData('''JiberishUIDB = {
            ["version"] = 1, ["profiles"] = { ["Default"] = {
                ["skin"] = "human", ["global"] = {}, ["groups"] = {
                    ["player"] = { ["skin"] = "alliance", ["healthMode"] = "class" },
                },
            } }, ["characters"] = {},
        }''').database()
        self.assertEqual(export(db['profiles']['Default']),
            'JUI1\ngroups.player.healthMode=s:class\ngroups.player.skin=s:alliance\nskin=s:human\n')

    def test_colors_numbers_booleans_and_escapes(self):
        db = SavedData(r'''JiberishUIDB = { ["version"] = 1, ["text"] = "quote\" and \\ and \065",
            ["profiles"] = { ["Default"] = { ["skin"] = "human", ["global"] = {
                ["enabled"] = false, ["opacity"] = 5e-1, ["tint"] = {1,0.5,0},
            }, ["groups"] = {} } } }''').database()
        self.assertEqual(db['text'], 'quote" and \\ and A')
        output = export(db['profiles']['Default'])
        self.assertIn('global.enabled=b:false', output)
        self.assertIn('global.opacity=n:0.5', output)
        self.assertIn('global.tint.2=n:0.5', output)

    def test_executable_lua_is_rejected(self):
        for content in ('os.execute("bad")', 'JiberishUIDB = loadstring("bad")()',
                        'JiberishUIDB = { ["version"] = 1 }; os.execute("bad")',
                        'JiberishUIDB = { ["version"] = 1, ["value"] = function() end }'):
            with self.assertRaises(ValueError):
                SavedData(content).database()

    def test_duplicates_future_versions_and_excessive_data(self):
        for content in ('JiberishUIDB = { ["version"] = 99 }',
                        'JiberishUIDB = { ["version"] = true }',
                        'JiberishUIDB = { ["version"] = 1, ["version"] = 1 }',
                        'JiberishUIDB = { ["version"] = 1, ["x"] = 1e999 }',
                        'JiberishUIDB = ' + '{'*20 + '}'*20,
                        ' ' * 2_000_001):
            with self.assertRaises(ValueError):
                SavedData(content).database()


if __name__ == '__main__':
    unittest.main()
