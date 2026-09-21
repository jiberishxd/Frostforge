"""Render repeatable artwork and native-outline review sheets from prepared atlas pixels."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'artwork/portraits'


def main():
    entries = json.loads((ART / 'manifest.json').read_text())['assets']
    for shape, folder, radius in (('player', 'assets', 60), ('round', 'round', 58)):
        sheet = Image.new('RGB', (7*256, 6*288), '#25463c')
        for i, entry in enumerate(entries):
            tile = Image.new('RGBA', (256,256), '#25463c')
            tile.alpha_composite(Image.open(ART / folder / (entry['id']+'.png')))
            draw = ImageDraw.Draw(tile)
            draw.ellipse((154-radius,148-radius,154+radius,148+radius),
                         fill='#101612', outline='#ad853b', width=3)
            if shape == 'player':
                draw.rectangle((154,148,214,208), fill='#101612')
                draw.line([(154,208),(214,208),(214,148)], fill='#ad853b', width=3)
            # This is a synthetic native badge guide, never addon artwork.
            draw.ellipse((82,174,133,225), fill='#131713', outline='#ad853b', width=3)
            if shape == 'round':
                tile = ImageOps.mirror(tile)
            sheet.paste(tile.convert('RGB'), ((i%7)*256,(i//7)*288+20))
            ImageDraw.Draw(sheet).text(((i%7)*256+8,(i//7)*288+5), entry['label'], fill='white')
        sheet.save(ART / (shape+'-fit-review.png'))

    for name, choices in (('collection-review', entries),
                          ('classes-review', [a for a in entries if a['group']=='class'])):
        sheet = Image.new('RGB', (7*184, ((len(choices)+6)//7)*192), '#242a30')
        for i, entry in enumerate(choices):
            artwork = Image.open(ART / 'assets' / (entry['id']+'.png')).resize((160,160), Image.Resampling.LANCZOS)
            tile = Image.new('RGBA', (160,160), '#242a30')
            tile.alpha_composite(artwork)
            sheet.paste(tile.convert('RGB'), ((i%7)*184+12,(i//7)*192))
            ImageDraw.Draw(sheet).text(((i%7)*184+12,(i//7)*192+164), entry['label'], fill='white')
        sheet.save(ART / (name+'.png'))


if __name__ == '__main__':
    main()
