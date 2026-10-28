"""Same web export and checks locally and in GitHub Actions; standard library only."""
import argparse
import datetime
import json
import re
import subprocess
from pathlib import Path
from install_godot_web import ROOT, install, runtime_env

CHECKS = ['silencer_portrait_check', 'pause_settings_check', 'web_cycle_check', 'player_health_check', 'enemy_check', 'damage_healing_check']


def run(editor, args, timeout=180):
    result = subprocess.run([editor, '--headless', '--path', str(ROOT), *args],
                            env=runtime_env(), cwd=ROOT, capture_output=True, text=True,
                            errors='replace', timeout=timeout)
    print(result.stdout, end='')
    print(result.stderr, end='')
    if result.returncode or 'SCRIPT ERROR:' in result.stderr or 'Shader compilation failed' in result.stderr:
        raise RuntimeError(f'Godot command failed: {args}')
    return result.stdout


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--skip-tests', action='store_true')
    args = parser.parse_args()
    editor = install()
    run(editor, ['--editor', '--quit'])
    if not args.skip_tests:
        for check in CHECKS:
            output = run(editor, ['--script', f'tests/{check}.gd'], timeout=90)
            if 'PASS:' not in output:
                raise RuntimeError(f'{check} did not report success')
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d%H%M%S')
    revision = subprocess.run(['git', '-c', f'safe.directory={ROOT.as_posix()}', 'rev-parse', '--short=10', 'HEAD'], cwd=ROOT, capture_output=True, text=True).stdout.strip()
    revision = re.sub('[^a-zA-Z0-9-]', '', revision) or 'local'
    build_id = f'{revision}-{stamp}'
    out = ROOT / 'build' / 'web'
    out.mkdir(parents=True, exist_ok=True)
    entry = f'game-{build_id}.html'
    run(editor, ['--export-release', 'Web', str(out / entry)])
    for suffix in ('.html', '.js', '.wasm', '.pck'):
        artifact = out / (Path(entry).stem + suffix)
        if not artifact.exists() or artifact.stat().st_size == 0:
            raise RuntimeError(f'Missing exported artifact: {artifact}')
    metadata = {'revision': revision, 'built_at': stamp, 'entry': entry}
    (out / 'build.json').write_text(json.dumps(metadata), encoding='utf-8')
    (out / 'index.html').write_text((ROOT / 'web' / 'launcher.html').read_text(encoding='utf-8'), encoding='utf-8')
    (out / '404.html').write_text((ROOT / 'web' / 'launcher.html').read_text(encoding='utf-8'), encoding='utf-8')
    (out / '.nojekyll').touch()
    print(f'PASS: web build {build_id}; serve {out} over HTTP, not file://')

if __name__ == '__main__':
    main()
