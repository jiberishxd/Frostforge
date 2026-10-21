"""Fit event decorations without changing character proportions.

The hub's outer sculptures and central medallion use a single uniform scale.
Only the two connecting rail spans change width. Ring ornaments use one uniform
scale and translation; they are never bent around an aperture by a radial warp.
"""
import numpy as np
from PIL import Image
from fit_minimaps import edges, remove_specks


def clean_alpha(image, threshold=8):
    pixels = np.array(image)
    pixels[pixels[:, :, 3] < threshold] = 0
    return Image.fromarray(pixels)


def fit_hub(source, rail_band=None):
    width, height = source.size
    alpha = np.asarray(source)[:, :, 3]
    tops, bottoms = [], []
    for fraction in np.r_[np.linspace(.36, .43, 12), np.linspace(.60, .66, 12)]:
        ys = np.where(alpha[int(height*.58):int(height*.94), int(width*fraction)] > 128)[0]
        if len(ys):
            tops.append(int(ys[0])+int(height*.58))
            # The first solid run is the rail; exclude cloth below it.
            breaks = np.where(np.diff(ys) > 1)[0]
            last = int(ys[breaks[0]]) if len(breaks) else int(ys[-1])
            bottoms.append(last+int(height*.58)+1)
    assert tops and bottoms, 'Missing hub rail'
    top, bottom = float(np.median(tops)), float(np.median(bottoms))
    if rail_band is not None:
        # A reviewed landmark can separate a rail from touching hanging cloth.
        top, bottom = map(float, rail_band)
    assert bottom > top, 'Empty hub rail'
    rail_center = (top+bottom)/2
    _, columns = np.where(alpha[:int(height*.61)] > 32)
    left = float(columns[columns < width/2].max()+4)
    right = float(columns[columns >= width/2].min()-4)
    assert left < width*.38 and right > width*.62, 'Endcaps enter the button corridor'
    bbox = source.getchannel('A').point(lambda a: 255 if a > 16 else 0).getbbox()
    scale = min(600/left, 600/(width-right),
                (575-12)/(rail_center-bbox[1]),
                (712-575)/(bbox[3]-rail_center), 90/(bottom-top))
    center_alpha = alpha[:, int(left):int(right)]
    rows = np.where((center_alpha > 32).sum(axis=1) > 4)[0]
    if rows[0] < rail_center:
        scale = min(scale, (575-448)/(rail_center-rows[0]))
    offset_y = 575-rail_center*scale
    center = width/2
    source_x = [left-620/scale, left, center-115/scale,
                center+115/scale, right, right+620/scale]
    target_x = [0, 620, 980, 1210, 1552, 2172]
    assert all(b > a for a, b in zip(source_x, source_x[1:]))
    mesh = []
    sy, ey = -offset_y/scale, (724-offset_y)/scale
    for sx, ex, dx, fx in zip(source_x, source_x[1:], target_x, target_x[1:]):
        mesh.append(((dx, 0, fx, 724), (sx, sy, sx, ey, ex, ey, ex, sy)))
    result = source.convert('RGBa').transform((2172, 724), Image.Transform.MESH,
                                            mesh, Image.Resampling.BICUBIC).convert('RGBA')
    result = clean_alpha(result)
    pixels = np.array(result)
    assert (pixels[:440, 620:1552, 3] > 32).sum() < 64, 'Hub ornaments enter button space'
    pixels[:440, 620:1552] = 0
    pixels[:4] = 0; pixels[-4:] = 0; pixels[:, :4] = 0; pixels[:, -4:] = 0
    return Image.fromarray(pixels), dict(method='uniform ornaments; flexible connecting rails',
        ornament_scale=scale, ornament_scale_xy=[scale, scale], offset_y=offset_y,
        source_x=source_x, target_x=target_x, source_rail=[top, bottom])


def measure_circle(source):
    """Robustly measure the opening without moving any ornament pixels."""
    alpha = np.asarray(source)[:, :, 3]
    angles, first = edges(alpha, 256, 256)
    x, y = 256+np.cos(angles)*first, 256+np.sin(angles)*first
    keep = np.ones(len(x), dtype=bool)
    for _ in range(5):
        a = np.column_stack((2*x[keep], 2*y[keep], np.ones(keep.sum())))
        cx, cy, c = np.linalg.lstsq(a, x[keep]**2+y[keep]**2, rcond=None)[0]
        radius = np.sqrt(c+cx*cx+cy*cy)
        residual = np.abs(np.hypot(x-cx, y-cy)-radius)
        keep = residual <= max(3, np.quantile(residual, .8))
    return [float(cx), float(cy), float(radius)]


def fit_minimap(source):
    assert source.width == source.height, 'Minimap source must be square'
    source = source.convert('RGBa').resize((512, 512), Image.Resampling.LANCZOS).convert('RGBA')
    cx, cy, radius = measure_circle(source)
    bounds = source.getchannel('A').point(lambda a: 255 if a > 16 else 0).getbbox()
    # Fit the complete silhouette uniformly. When the source rim is thick,
    # trim its inward-facing pixels to the aperture instead of bending faces.
    scale = min(149/radius, 246/(cx-bounds[0]), 246/(bounds[2]-cx),
                246/(cy-bounds[1]), 246/(bounds[3]-cy))
    result = source.convert('RGBa').transform((512, 512), Image.Transform.AFFINE,
        (1/scale, 0, cx-256/scale, 0, 1/scale, cy-256/scale),
        Image.Resampling.BICUBIC).convert('RGBA')
    pixels = np.array(result)
    yy, xx = np.mgrid[:512, :512]
    outside = (xx < 8) | (yy < 8) | (xx >= 504) | (yy >= 504)
    clipped = int(((pixels[:, :, 3] > 32) & outside).sum())
    assert clipped < 128, f'Minimap needs more source margin: {clipped} pixels'
    pixels[((xx-256)**2+(yy-256)**2 <= 149**2) | outside] = 0
    return remove_specks(clean_alpha(Image.fromarray(pixels))), dict(
        method='uniform scale and translation; inward rim trimmed to aperture; no radial warp', source_circle=[cx,cy,radius],
        ornament_scale_xy=[scale,scale], margin_pixels_removed=clipped)


def fit_portrait(source):
    """Align the C opening using its left/lower arc, keeping the hood rigid."""
    source = source.convert('RGBa').resize((256,256), Image.Resampling.LANCZOS).convert('RGBA')
    alpha = np.asarray(source)[:, :, 3]
    angles = np.deg2rad(np.arange(75,276))
    radii = np.arange(24,150)
    x = np.rint(154+np.cos(angles[:,None])*radii).astype(int)
    y = np.rint(148+np.sin(angles[:,None])*radii).astype(int)
    valid = (x >= 0) & (x < 256) & (y >= 0) & (y < 256)
    solid = (alpha[np.clip(y,0,255),np.clip(x,0,255)] > 96) & valid
    runs = solid[:,:-2] & solid[:,1:-1] & solid[:,2:]
    present = runs.any(axis=1)
    assert present.mean() > .95, 'Incomplete portrait arc'
    edge = np.argmax(runs,axis=1)+24
    x,y = 154+np.cos(angles)*edge,148+np.sin(angles)*edge
    keep = present.copy()
    for _ in range(5):
        a = np.column_stack((2*x[keep],2*y[keep],np.ones(keep.sum())))
        cx,cy,c = np.linalg.lstsq(a,x[keep]**2+y[keep]**2,rcond=None)[0]
        radius = np.sqrt(c+cx*cx+cy*cy)
        residual = np.abs(np.hypot(x-cx,y-cy)-radius)
        keep = present & (residual <= max(2,np.quantile(residual,.8)))
    bounds = source.getchannel('A').point(lambda a: 255 if a > 16 else 0).getbbox()
    scale = min(58/radius,144/(cx-bounds[0]),138/(cy-bounds[1]),94/(bounds[3]-cy))
    fitted = source.convert('RGBa').transform((256,256),Image.Transform.AFFINE,
        (1/scale,0,cx-154/scale,0,1/scale,cy-148/scale),Image.Resampling.BICUBIC).convert('RGBA')
    atlas = Image.new('RGBA',(512,256))
    yy,xx = np.mgrid[:256,:256]
    for index,radius in enumerate((60,58)):
        pixels = np.array(fitted)
        clear = ((xx-154)**2+(yy-148)**2 <= radius**2) | (xx < 8) | (xx >= 214) | (yy < 8) | (yy >= 244)
        if index == 0: clear |= (xx >= 154) & (xx <= 214) & (yy >= 148) & (yy <= 208)
        pixels[clear] = 0
        atlas.paste(clean_alpha(Image.fromarray(pixels)),(256*index,0))
    return atlas, dict(method='uniform scale and translation; clear native openings; no contour warp',
        source_circle=[float(cx),float(cy),float(np.sqrt(c+cx*cx+cy*cy))],
        ornament_scale_xy=[float(scale),float(scale)],source_bounds=list(bounds))
