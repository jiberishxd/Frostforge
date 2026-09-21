"""Recover JUI1 exports from a WoW SavedVariables file without executing its Lua.

Reads only the simple data-table syntax emitted by WoW. Never modifies the source.
Validate the resulting exports with JiberishUI's normal profile importer.
"""
import argparse
import json
import math
from pathlib import Path
import re


class SavedData:
    def __init__(self, text):
        if len(text) > 2_000_000:
            raise ValueError('Saved file is too large.')
        self.text, self.i, self.values = text, 0, 0

    def space(self):
        while self.i < len(self.text):
            if self.text[self.i].isspace():
                self.i += 1
            elif self.text.startswith('--', self.i):
                end = self.text.find('\n', self.i)
                self.i = len(self.text) if end < 0 else end + 1
            else:
                break

    def take(self, token):
        self.space()
        if not self.text.startswith(token, self.i):
            raise ValueError('Unexpected saved-data syntax.')
        self.i += len(token)

    def value(self, depth=0):
        self.space()
        self.values += 1
        if depth > 12 or self.values > 100_000 or self.i >= len(self.text):
            raise ValueError('Invalid or excessive saved data.')
        char = self.text[self.i]
        if char == '{':
            self.i += 1
            result, index = {}, 1
            while True:
                self.space()
                if self.text.startswith('}', self.i):
                    self.i += 1
                    return result
                if self.text.startswith('[', self.i):
                    self.i += 1
                    key = self.value(depth + 1)
                    self.take(']'); self.take('=')
                else:
                    key, index = index, index + 1
                if type(key) not in (str, int) or key in result:
                    raise ValueError('Invalid or duplicate table key.')
                result[key] = self.value(depth + 1)
                self.space()
                if self.text.startswith(',', self.i):
                    self.i += 1
                elif not self.text.startswith('}', self.i):
                    raise ValueError('Expected table separator.')
        if char in ('"', "'"):
            quote = char
            self.i += 1
            result = []
            while self.i < len(self.text):
                char = self.text[self.i]; self.i += 1
                if char == quote:
                    return ''.join(result)
                if char == '\\':
                    if self.i >= len(self.text):
                        raise ValueError('Unterminated escape.')
                    escaped = self.text[self.i]; self.i += 1
                    if escaped.isdigit():
                        digits = escaped
                        while self.i < len(self.text) and len(digits) < 3 and self.text[self.i].isdigit():
                            digits += self.text[self.i]; self.i += 1
                        if int(digits) > 255:
                            raise ValueError('Invalid byte escape.')
                        char = chr(int(digits))
                    else:
                        escapes = {'n':'\n','r':'\r','t':'\t','\\':'\\','"':'"',"'":"'"}
                        if escaped not in escapes:
                            raise ValueError('Unsupported string escape.')
                        char = escapes[escaped]
                result.append(char)
            raise ValueError('Unterminated string.')
        match = re.match(r'(true|false|nil)(?![\w])|-?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?', self.text[self.i:])
        if not match:
            raise ValueError('Executable Lua and non-data values are not accepted.')
        raw = match.group(); self.i += len(raw)
        if raw in ('true', 'false', 'nil'):
            return {'true':True, 'false':False, 'nil':None}[raw]
        number = float(raw) if any(c in raw for c in '.eE') else int(raw)
        if not math.isfinite(number):
            raise ValueError('Non-finite number.')
        return number

    def database(self):
        self.take('JiberishUIDB'); self.take('=')
        result = self.value()
        self.space()
        if (self.i != len(self.text) or not isinstance(result, dict)
                or type(result.get('version')) not in (int, float) or result['version'] != 1):
            raise ValueError('Not a supported JiberishUI saved database.')
        return result


def export(profile):
    if not isinstance(profile, dict):
        raise ValueError('Profile is not a data table.')
    lines = ['JUI1']
    def walk(value, prefix=''):
        for raw_key in sorted(value, key=str):
            key = str(raw_key)
            if not re.fullmatch(r'[A-Za-z0-9_]+', key):
                raise ValueError('Invalid profile field.')
            path = prefix + '.' + key if prefix else key
            item = value[raw_key]
            if isinstance(item, dict):
                walk(item, path)
            elif type(item) is bool:
                lines.append(path + '=b:' + str(item).lower())
            elif type(item) in (int, float):
                lines.append(path + '=n:' + format(item, '.17g'))
            elif isinstance(item, str) and not any(c in item for c in '\r\n'):
                lines.append(path + '=s:' + item)
            else:
                raise ValueError('Invalid profile value.')
    walk(profile)
    return '\n'.join(lines) + '\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('saved_file', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    db = SavedData(args.saved_file.read_text(encoding='utf-8-sig')).database()
    profiles = db.get('profiles')
    if not isinstance(profiles, dict):
        raise ValueError('No profiles found.')
    exports = [(name, export(value)) for name, value in profiles.items()]
    args.output.mkdir(parents=True, exist_ok=False)
    index = []
    for i, (name, content) in enumerate(exports, 1):
        filename = f'profile-{i}.jui.txt'
        (args.output/filename).write_text(content)
        index.append({'profile': name, 'file': filename})
    (args.output/'profiles.json').write_text(json.dumps(index, indent=2) + '\n')
    print(f'Recovered {len(exports)} profile(s). Source file was not changed.')


if __name__ == '__main__':
    main()
