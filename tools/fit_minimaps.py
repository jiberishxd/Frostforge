"""Register decorative minimap pixels around one shared circular aperture."""
import numpy as np
from PIL import Image
from collections import deque

SIZE = 512
CENTER = 256
RADIUS = 149


def remove_specks(image):
    """Drop tiny detached matte fragments, retaining substantial ornaments."""
    data = np.array(image)
    alpha = data[:, :, 3]
    seen = np.zeros(alpha.shape, dtype=bool)
    for y, x in zip(*np.where(alpha > 0)):
        if seen[y, x]:
            continue
        seen[y, x] = True
        queue = deque([(int(y), int(x))])
        part = []
        while queue:
            py, px = queue.popleft()
            part.append((py, px))
            for dy, dx in ((-1,0), (1,0), (0,-1), (0,1)):
                ny, nx = py+dy, px+dx
                if 0 <= ny < SIZE and 0 <= nx < SIZE and alpha[ny,nx] > 0 and not seen[ny,nx]:
                    seen[ny,nx] = True
                    queue.append((ny,nx))
        if len(part) < 200:
            for py, px in part:
                data[py, px] = 0
    return Image.fromarray(data)


def edges(alpha, cx, cy):
    angles = np.linspace(-np.pi, np.pi, 720, endpoint=False)
    radii = np.arange(70, 246)
    x = np.rint(cx + np.cos(angles[:, None])*radii).astype(int)
    y = np.rint(cy + np.sin(angles[:, None])*radii).astype(int)
    valid = (x >= 0) & (x < SIZE) & (y >= 0) & (y < SIZE)
    solid = (alpha[np.clip(y, 0, SIZE-1), np.clip(x, 0, SIZE-1)] > 96) & valid
    runs = solid[:, :-2] & solid[:, 1:-1] & solid[:, 2:]
    present = runs.any(axis=1)
    assert present.mean() > .95, 'Incomplete circular minimap rim'
    first = np.where(present, np.argmax(runs, axis=1)+70, 149).astype(float)
    return angles, first


def conform(source):
    source = source.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    alpha = np.array(source.getchannel('A'))
    angles, first = edges(alpha, CENTER, CENTER)
    x = CENTER + np.cos(angles)*first
    y = CENTER + np.sin(angles)*first
    keep = np.ones(len(x), dtype=bool)
    # Fit the circular body robustly; top and bottom flourishes are outliers.
    for _ in range(5):
        a = np.column_stack((2*x[keep], 2*y[keep], np.ones(keep.sum())))
        cx, cy, c = np.linalg.lstsq(a, x[keep]**2+y[keep]**2, rcond=None)[0]
        r = np.sqrt(c+cx*cx+cy*cy)
        residual = np.abs(np.hypot(x-cx, y-cy)-r)
        keep = residual <= max(3, np.quantile(residual, .8))
    assert 200 < cx < 310 and 200 < cy < 320 and 100 < r < 200, (cx, cy, r)
    angles, first = edges(alpha, cx, cy)
    first = np.median(np.stack([np.roll(first, k) for k in range(-5, 6)]), axis=0)
    kernel = np.exp(-np.arange(-18, 19)**2/(2*6**2)); kernel /= kernel.sum()
    first = np.convolve(np.pad(first, (18, 18), mode='wrap'), kernel, mode='valid')
    yy, xx = np.mgrid[:SIZE, :SIZE]
    dx, dy = xx-CENTER, yy-CENTER
    theta = np.arctan2(dy, dx)
    distance = np.hypot(dx, dy)
    cosine, sine = np.cos(theta), np.sin(theta)
    old = first[np.floor((theta+np.pi)*720/(2*np.pi)).astype(int) % 720]
    # Map canvas boundaries as well as the inner edge, retaining whole crests.
    far_x = np.where(cosine >= 0, SIZE-1-cx, cx) / np.maximum(np.abs(cosine), 1e-6)
    far_y = np.where(sine >= 0, SIZE-1-cy, cy) / np.maximum(np.abs(sine), 1e-6)
    old_far = np.minimum(far_x, far_y)
    new_far = (CENTER-8) / np.maximum(np.abs(cosine), np.abs(sine))
    mapped = old + (distance-RADIUS)*(old_far-old)/(new_far-RADIUS)
    sx, sy = cx+cosine*mapped, cy+sine*mapped
    data = np.asarray(source, dtype=float)/255
    data[:, :, :3] *= data[:, :, 3:4]
    x0, y0 = np.floor(sx).astype(int), np.floor(sy).astype(int)
    fx, fy = sx-x0, sy-y0
    out = np.zeros((SIZE, SIZE, 4))
    for ox, oy, weight in ((0,0,(1-fx)*(1-fy)), (1,0,fx*(1-fy)), (0,1,(1-fx)*fy), (1,1,fx*fy)):
        x, y = x0+ox, y0+oy
        valid = (x >= 0) & (x < SIZE) & (y >= 0) & (y < SIZE)
        out += data[np.clip(y,0,SIZE-1), np.clip(x,0,SIZE-1)]*(weight*valid)[:, :, None]
    out[:, :, :3] /= np.maximum(out[:, :, 3:4], 1/255)
    clear = (distance <= RADIUS) | (xx < 8) | (yy < 8) | (xx >= SIZE-8) | (yy >= SIZE-8)
    out[clear] = 0
    out[out[:, :, 3] < 8/255] = 0
    result = remove_specks(Image.fromarray(np.uint8(np.clip(out*255, 0, 255))))
    return result, [float(cx), float(cy), float(r)]
