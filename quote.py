# Serves a random quote on :80 and :443 for any blocked site. Run as root by launchd.
import html, random, socket, ssl, threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

CERT, KEY = "/usr/local/etc/blocker/cert.pem", "/usr/local/etc/blocker/key.pem"
QUOTES = [
    ("You have power over your mind, not outside events. Realize this, and you will find strength.", "Marcus Aurelius"),
    ("It is not that we have a short time to live, but that we waste a lot of it.", "Seneca"),
    ("We suffer more often in imagination than in reality.", "Seneca"),
    ("Well begun is half done.", "Aristotle"),
    ("The secret of getting ahead is getting started.", "Mark Twain"),
    ("Lost time is never found again.", "Benjamin Franklin"),
    ("Concentrate all your thoughts upon the work at hand.", "Alexander Graham Bell"),
    ("Do not wait; the time will never be just right.", "Napoleon Hill"),
    ("First say to yourself what you would be; and then do what you have to do.", "Epictetus"),
    ("How we spend our days is, of course, how we spend our lives.", "Annie Dillard"),
]
PAGE = """<!doctype html><meta charset=utf-8><meta name=viewport content="width=device-width">
<title>Back to work</title>
<style>body{margin:0;min-height:100vh;display:grid;place-items:center;background:#111;color:#eee;
font:1.6rem/1.5 Georgia,serif;padding:1rem;box-sizing:border-box}figure{max-width:40rem;margin:0}
figcaption{margin-top:1rem;font-size:1rem;color:#999}</style>
<figure><blockquote>&ldquo;{q}&rdquo;</blockquote><figcaption>&mdash; {a}</figcaption></figure>"""


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        q, a = random.choice(QUOTES)
        body = PAGE.replace("{q}", html.escape(q)).replace("{a}", html.escape(a)).encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    do_POST = do_GET

    def log_message(self, *args):
        pass


class Server(ThreadingHTTPServer):
    address_family = socket.AF_INET6  # dual-stack: hosts maps sites to 127.0.0.1 and ::1

    def server_bind(self):
        self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)
        super().server_bind()


http = Server(("::", 80), Handler)
https = Server(("::", 443), Handler)
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ctx.load_cert_chain(CERT, KEY)
# handshake in the handler thread, so a stalled client can't block accept()
https.socket = ctx.wrap_socket(https.socket, server_side=True, do_handshake_on_connect=False)
threading.Thread(target=http.serve_forever, daemon=True).start()
https.serve_forever()
