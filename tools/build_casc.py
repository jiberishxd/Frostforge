"""Build the local, read-only CascLib extraction dependency on macOS."""
from pathlib import Path
import concurrent.futures
import re
import subprocess

root = Path(__file__).resolve().parents[1]
src = root / '.tools/CascLib'
obj = root / '.tools/casc-objects'
obj.mkdir(exist_ok=True)
files = re.search(r'set\(SRC_FILES(.*?)\)', (src / 'CMakeLists.txt').read_text(), re.S)[1].split()
def build(file):
    target = obj / (file.replace('/', '_') + '.o')
    subprocess.run(['clang' if file.endswith('.c') else 'clang++', '-O2', '-fPIC',
                    '-DCASC_USE_SYSTEM_ZLIB', '-DCASCLIB_NO_AUTO_LINK_LIBRARY', '-DCASCLIB_NODEBUG',
                    '-c', str(src / file), '-o', str(target)], check=True, capture_output=True)
    return str(target)
with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
    objects = list(pool.map(build, files))
subprocess.run(['clang++', '-dynamiclib', *objects, '-lz', '-o', str(root / '.tools/libcasc.dylib')], check=True)
subprocess.run(['clang++', '-std=c++17', '-I'+str(src/'src'), str(root/'tools/casc_extract.cpp'),
                str(root/'.tools/libcasc.dylib'), '-o', str(root/'.tools/casc_extract')], check=True)
print('Built .tools/libcasc.dylib and .tools/casc_extract')
