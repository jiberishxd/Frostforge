"""Render retained/current hub comparisons without modifying approved artwork."""
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'artwork/hubs'

def main():
    progress=json.loads((ART/'style-remaster/progress.json').read_text())
    assets=json.loads((ART/'manifest.json').read_text())['assets']
    revised=[a for a in assets if a.get('style_remaster')]
    for a in revised:
        progress['themes'][a['id']]['status']='integrated'
    (ART/'style-remaster/progress.json').write_text(json.dumps(progress,indent=2)+'\n')
    for offset in range(0,len(revised),6):
        chunk=revised[offset:offset+6]
        sheet=Image.new('RGB',(1200,len(chunk)*234),'#233630')
        draw=ImageDraw.Draw(sheet)
        for row,a in enumerate(chunk):
            draw.text((12,row*234+8),a['label']+'   |   Previous / Sculpted update',fill='#f2dfb3')
            for col,base in enumerate(['style-remaster/before/assets','assets']):
                im=Image.open(ART/base/(a['id']+'.png')).convert('RGBA').resize((588,196),Image.Resampling.LANCZOS)
                sheet.paste(im,(6+col*600,row*234+28),im)
        sheet.save(ART/'style-remaster/previews'/f'comparison-{offset//6+1}.png')
    print(f'Rendered {len(revised)} restyled hub comparisons.')

if __name__=='__main__':main()
