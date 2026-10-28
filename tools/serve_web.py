"""Local preview only. Public hosting uses GitHub Pages."""
import argparse
import functools
import http.server
from pathlib import Path
parser = argparse.ArgumentParser()
parser.add_argument('--port', type=int, default=8765)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1] / 'build' / 'web'
if not (root / 'index.html').exists():
    raise SystemExit('Run python tools/web_build.py first.')
class Preview(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map, '.wasm': 'application/wasm'}
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()
print(f'Preview: http://127.0.0.1:{args.port}/', flush=True)
http.server.ThreadingHTTPServer(('127.0.0.1', args.port), functools.partial(Preview, directory=str(root))).serve_forever()
