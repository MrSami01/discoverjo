from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import os
import webbrowser

ROOT = Path(__file__).resolve().parent
PORT = 4173


class SiteHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def do_GET(self):
        requested = self.translate_path(self.path)
        if not Path(requested).is_file() and not Path(requested).is_dir():
            self.path = "/index.html"
        super().do_GET()


if __name__ == "__main__":
    os.chdir(ROOT)
    address = f"http://127.0.0.1:{PORT}/"
    server = ThreadingHTTPServer(("127.0.0.1", PORT), SiteHandler)
    print(f"Atharna preview: {address}")
    print("Keep this terminal open. Press Ctrl+C to stop.")
    webbrowser.open(address)
    server.serve_forever()
