"""Install the pinned official editor/web templates into this workspace only."""
import hashlib
import os
import platform
import shutil
import subprocess
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION = '4.7'
CACHE = ROOT / '.godot' / 'toolchain' / VERSION
DATA = ROOT / '.godot' / 'web-user'
BASE = f'https://github.com/godotengine/godot/releases/download/{VERSION}-stable/'


def runtime_env():
    env = os.environ.copy()
    env['APPDATA'] = str(DATA)
    env['XDG_DATA_HOME'] = str(DATA)
    return env


def download(name):
    CACHE.mkdir(parents=True, exist_ok=True)
    target = CACHE / name
    if target.exists():
        return target
    print(f'Downloading official {name}', flush=True)
    request = urllib.request.Request(BASE + name, headers={'User-Agent': 'VectorFall-build'})
    partial = target.with_suffix(target.suffix + '.partial')
    with urllib.request.urlopen(request, timeout=120) as response, partial.open('wb') as out:
        shutil.copyfileobj(response, out, length=1024 * 1024)
    partial.replace(target)
    return target


def verified_archive(name):
    checksums = download('SHA512-SUMS.txt').read_text()
    expected = next((line.split()[0] for line in checksums.splitlines()
                     if line.split() and line.split()[-1].lstrip('*') == name), None)
    if expected is None:
        raise RuntimeError(f'Official checksum missing for {name}')
    archive = download(name)
    with archive.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha512').hexdigest()
    if digest.lower() != expected.lower():
        raise RuntimeError(f'Checksum mismatch for {name}; remove {archive} and retry')
    return archive


def install():
    DATA.mkdir(parents=True, exist_ok=True)
    editor = os.environ.get('GODOT_BIN') or shutil.which('godot')
    if not editor:
        filename = f'Godot_v{VERSION}-stable_win64_console.exe' if platform.system() == 'Windows' else f'Godot_v{VERSION}-stable_linux.x86_64'
        editor_path = CACHE / filename
        if not editor_path.exists():
            archive_name = f'Godot_v{VERSION}-stable_win64.exe.zip' if platform.system() == 'Windows' else f'Godot_v{VERSION}-stable_linux.x86_64.zip'
            archive = verified_archive(archive_name)
            with zipfile.ZipFile(archive) as package:
                for member in package.infolist():
                    name = Path(member.filename).name
                    if name.startswith(f'Godot_v{VERSION}-stable_') and not member.is_dir():
                        (CACHE / name).write_bytes(package.read(member))
            editor_path.chmod(0o755)
        editor = str(editor_path)
    reported = subprocess.check_output([editor, '--version'], env=runtime_env(), text=True).strip()
    if not reported.startswith(VERSION + '.stable.'):
        raise RuntimeError(f'Expected Godot {VERSION} stable, got {reported}')
    folder = DATA / ('Godot' if platform.system() == 'Windows' else 'godot') / 'export_templates' / f'{VERSION}.stable'
    if not (folder / 'web_nothreads_release.zip').exists():
        archive = verified_archive(f'Godot_v{VERSION}-stable_export_templates.tpz')
        folder.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(archive) as package:
            for member in package.infolist():
                name = Path(member.filename).name
                if name in ('web_nothreads_debug.zip', 'web_nothreads_release.zip'):
                    print(f'Installing {name}', flush=True)
                    (folder / name).write_bytes(package.read(member))
        if not (folder / 'web_nothreads_release.zip').exists():
            raise RuntimeError('Single-threaded web release template missing from official package')
        archive.unlink()  # Keep the cache small: only installed web templates and editor.
    print(f'Using {reported}; web templates: {folder}', flush=True)
    return editor

if __name__ == '__main__':
    install()
