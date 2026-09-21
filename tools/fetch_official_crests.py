"""Collect the user-requested public Blizzard crests with their source provenance.

No credentials, account state or game settings are accessed. Asset selection is
from published page markup, not guessed CDN URLs. This is not a license grant.
"""
import hashlib
import json
import re
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'artwork/official-crests'
BASE = 'https://worldofwarcraft.blizzard.com/en-us'


def get(url):
    assert url.startswith(('https://worldofwarcraft.blizzard.com/', 'https://blz-contentstack-images.akamaized.net/'))
    with urllib.request.urlopen(url, timeout=40) as response:
        return response.read()


def state(html):
    match = re.search(r'var \w+InitialState = ', html)
    return json.JSONDecoder().raw_decode(html[match.end():])[0] if match else None


class Artwork(HTMLParser):
    def __init__(self):
        super().__init__()
        self.urls = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if attrs.get('class') == 'Art-image':
            match = re.search(r'url\([\"\']?(https:[^)\"\']+)', attrs.get('style', ''))
            if match and '.png' in match[1]:
                self.urls.append(match[1])


def main():
    (OUT / 'pages').mkdir(parents=True, exist_ok=True)
    (OUT / 'originals').mkdir(exist_ok=True)
    catalog = json.loads((ROOT / 'artwork/portraits/catalog.json').read_text())
    undead = state(get(BASE + '/game/races/undead').decode())
    race_links = {}
    for race in undead['moreRaces']['races']:
        race_links.setdefault(race['title'], race['link'])
    class_directory = get(BASE + '/game/classes').decode()
    class_links = set(re.findall(r'/game/classes/[a-z-]+', class_directory))
    jobs = []
    for token, label, _ in catalog['classes']:
        suffix = label.lower().replace(' ', '-')
        link = '/game/classes/' + suffix
        assert link in class_links, label
        jobs.append(('class_' + token.lower(), label, BASE + link, 'class'))
    for token, label, _ in catalog['races']:
        jobs.append(('race_' + token.lower(), label, BASE + race_links[label], 'race'))

    def fetch(job):
        id, label, page, group = job
        html = get(page).decode()
        (OUT / 'pages' / (id + '.html')).write_text(html)
        data = state(html)
        if group == 'race':
            asset_url = data['overview']['crest']['image']['url']
        else:
            parser = Artwork(); parser.feed(html)
            # First Art-image is the full class illustration; the next PNG is
            # the ornamental crest in the class-information panel.
            assert len(parser.urls) >= 2, (id, parser.urls)
            asset_url = parser.urls[1]
        content = get(asset_url)
        path = OUT / 'originals' / (id + '.png')
        path.write_bytes(content)
        print(id, 'saved', flush=True)
        return {'id': id, 'label': label, 'group': group, 'page': page,
                'url': asset_url, 'file': str(path.relative_to(ROOT)),
                'sha256': hashlib.sha256(content).hexdigest(),
                'credit': 'Blizzard Entertainment', 'permission_status': 'No separate permission obtained'}

    records = []
    with ThreadPoolExecutor(max_workers=4) as pool:
        for record in pool.map(fetch, jobs):
            records.append(record)
            (OUT / 'sources.json').write_text(json.dumps(records, indent=2) + '\n')

    for name, page_data in [('horde', undead), ('alliance', state(get(BASE + race_links['Human']).decode()))]:
        url = page_data['masthead']['faction_icon']['image']['url']
        content = get(url)
        path = OUT / 'originals' / ('faction_' + name + '.png'); path.write_bytes(content)
        records.append({'id':'faction_'+name, 'label':name.title(), 'group':'faction',
                        'page':BASE+('/game/races/undead' if name=='horde' else race_links['Human']),
                        'url':url, 'file':str(path.relative_to(ROOT)), 'sha256':hashlib.sha256(content).hexdigest(),
                        'credit':'Blizzard Entertainment','permission_status':'No separate permission obtained'})
    (OUT / 'sources.json').write_text(json.dumps(records, indent=2) + '\n')


if __name__ == '__main__':
    main()
