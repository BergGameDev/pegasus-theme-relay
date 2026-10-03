from urllib.parse import quote
import math
import calendar
try:
    from PIL import Image as PILImage
except ImportError:
    PILImage = None
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs, urlencode
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError
from pathlib import Path
import json, time, sys, os, re, shutil, threading

HOST = "127.0.0.1"
PORT = 47831
TOKEN_URL = "https://id.twitch.tv/oauth2/token"
IGDB_BASE = "https://api.igdb.com/v4/"

HERE = Path(__file__).resolve().parent
CONFIG_CANDIDATES = [
    HERE.parent.parent / "relay-config.json",  # theme/../../ when helper lives in theme
    HERE.parent / "relay-config.json",
    Path.cwd() / "relay-config.json",
    Path(sys.argv[1]).resolve() if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else None,
]

def find_config():
    for p in CONFIG_CANDIDATES:
        if p and p.is_file():
            return p
    # Typical portable layout: Pegasus\config\themes\RelayPegasus...\relay-metadata
    for parent in HERE.parents:
        p = parent / "relay-config.json"
        if p.is_file():
            return p
    raise FileNotFoundError("relay-config.json not found. Put it in the Pegasus root folder.")

def load_config():
    p = find_config()
    cfg = json.loads(p.read_text(encoding="utf-8-sig"))
    igdb = cfg.get("igdb", {})
    cid = str(igdb.get("client_id", "")).strip()
    secret = str(igdb.get("client_secret", "")).strip()
    if not cid or not secret:
        raise ValueError(f"IGDB client_id/client_secret missing in {p}")
    return p, cid, secret


def open_remote(req, timeout=15):
    """Retry transient failures once, including OAuth token acquisition."""
    for attempt in range(2):
        try:
            return urlopen(req, timeout=timeout)
        except HTTPError as error:
            if not attempt and (error.code == 429 or 500 <= error.code < 600):
                delay = min(2.0, max(0.35, float(error.headers.get("Retry-After", "0.35"))))
                error.close(); time.sleep(delay); continue
            raise
        except (URLError, TimeoutError, OSError):
            if attempt: raise
            time.sleep(0.35)

class IGDB:
    def __init__(self):
        self.config_path, self.client_id, self.client_secret = load_config()
        self.token = None
        self.token_expires = 0
        self.token_lock = threading.RLock()

    def ensure_token(self):
        if self.token and time.time() < self.token_expires - 60:
            return
        data = urlencode({
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "grant_type": "client_credentials",
        }).encode()
        req = Request(TOKEN_URL, data=data, method="POST")
        with open_remote(req, timeout=15) as r:
            payload = json.loads(r.read().decode())
        self.token = payload["access_token"]
        self.token_expires = time.time() + int(payload.get("expires_in", 0))

    def request(self, body, endpoint="games"):
        for auth_attempt in range(2):
            with self.token_lock:
                self.ensure_token()
                token = self.token
            req = Request(IGDB_BASE + endpoint, data=body.encode("utf-8"), method="POST", headers={
                "Client-ID": self.client_id, "Authorization": "Bearer " + token, "Content-Type": "text/plain",
            })
            try:
                with open_remote(req, timeout=15) as response:
                    return json.loads(response.read().decode())
            except HTTPError as error:
                if error.code == 401 and auth_attempt == 0:
                    with self.token_lock: self.token = None
                    error.close(); continue
                detail = error.read().decode("utf-8", errors="replace")
                raise RuntimeError(f"IGDB HTTP {error.code}: {detail[:300]}")

    @staticmethod
    def company_names(game):
        devs, pubs = [], []
        for inv in game.get("involved_companies") or []:
            company = inv.get("company") or {}
            name = company.get("name")
            if not name: continue
            if inv.get("developer"): devs.append(name)
            if inv.get("publisher"): pubs.append(name)
        return devs, pubs

    @staticmethod
    def normalized(game):
        devs, pubs = IGDB.company_names(game)
        ts = game.get("first_release_date")
        year = time.gmtime(ts).tm_year if ts else None
        return {
            "id": str(game["id"]),
            "title": game.get("name", ""),
            "year": year,
            "release_timestamp": ts,
            "developer": ", ".join(devs),
            "publisher": ", ".join(pubs),
            "genres": [g.get("name") for g in (game.get("genres") or []) if g.get("name")],
            "summary": game.get("summary", ""),
        }

    def search(self, query, limit=10):
        safe = query.replace("\\", "\\\\").replace('"', '\\"')
        body = (
            f'search "{safe}"; '
            'fields name,first_release_date,summary,genres.name,'
            'involved_companies.developer,involved_companies.publisher,involved_companies.company.name; '
            f'limit {int(limit)};'
        )
        return [self.normalized(g) for g in self.request(body)]

    def game(self, game_id):
        gid = int(game_id)
        body = (
            'fields name,first_release_date,summary,genres.name,'
            'involved_companies.developer,involved_companies.publisher,involved_companies.company.name; '
            f'where id = {gid}; limit 1;'
        )
        rows = self.request(body)
        return self.normalized(rows[0]) if rows else None

    @staticmethod
    def image_url(image_id, size):
        return f"https://images.igdb.com/igdb/image/upload/t_{size}/{image_id}.jpg"

    def artwork(self, game_id):
        gid = int(game_id)
        result = {"hero": [], "logo": [], "cover": []}

        artworks = self.request(
            f"fields image_id,width,height; where game = {gid}; limit 20;",
            "artworks"
        )
        screenshots = self.request(
            f"fields image_id,width,height; where game = {gid}; limit 20;",
            "screenshots"
        )
        covers = self.request(
            f"fields image_id,width,height; where game = {gid}; limit 10;",
            "covers"
        )
        logos = self.request(
            f"fields image_id,width,height; where game = {gid}; limit 10;",
            "logos"
        )

        seen = set()
        for item in artworks + screenshots:
            iid = item.get("image_id")
            if not iid or iid in seen: continue
            seen.add(iid)
            result["hero"].append({
                "id": iid, "url": self.image_url(iid, "1080p_2x" if (item.get("width") or 0)>1920 or (item.get("height") or 0)>1080 else "1080p"),
                "width": item.get("width"), "height": item.get("height"),
                "source": "IGDB artwork" if item in artworks else "IGDB screenshot"
            })
        for item in logos:
            iid = item.get("image_id")
            if iid:
                result["logo"].append({
                    "id": iid, "url": self.image_url(iid, "logo_med_2x"),
                    "width": item.get("width"), "height": item.get("height"),
                    "source": "IGDB logo"
                })
        for item in covers:
            iid = item.get("image_id")
            if iid:
                result["cover"].append({
                    "id": iid, "url": self.image_url(iid, "cover_big_2x"),
                    "width": item.get("width"), "height": item.get("height"),
                    "source": "IGDB cover"
                })
        return result

provider = None
startup_error = None
try:
    provider = IGDB()
except Exception as e:
    startup_error = str(e)


GENERATED_NAME = "relay-curated.metadata.pegasus.txt"
MEDIA_DIR = "relay-curated-media"

def safe_slug(text):
    text = re.sub(r'[<>:"/\\|?*]+', "_", text or "game")
    return re.sub(r"\s+", " ", text).strip(" .")[:120] or "game"

def find_metadata_root(game_path):
    p = Path(game_path).resolve()
    for parent in [p.parent] + list(p.parents):
        if (parent / "metadata.pegasus.txt").is_file() or (parent / "metadata.txt").is_file():
            return parent
    return p.parent

def load_generated(root):
    path = root / GENERATED_NAME
    if not path.is_file(): return {}
    text = path.read_text(encoding="utf-8")
    blocks = {}
    for block in re.split(r"\n(?=game: )", text.strip()):
        m = re.search(r"^x-relay-file:\s*(.+)$", block, re.M)
        if m: blocks[m.group(1).strip()] = block.strip()
    return blocks

def save_generated(root, blocks):
    path = root / GENERATED_NAME
    header = "# Generated by Relay Metadata Helper. Safe to delete.\n"
    if not blocks:
        # Keep an empty, valid source file once created so Pegasus can continue watching it.
        path.write_text(header, encoding="utf-8")
        return
    path.write_text(header + "\n\n".join(blocks.values()) + "\n", encoding="utf-8")

def download(url, dest):
    if not url: return None
    dest.parent.mkdir(parents=True, exist_ok=True)
    req = Request(url, headers={"User-Agent":"RelayMetadata/0.7.2"})
    with open_remote(req, timeout=30) as r, open(dest, "wb") as f:
        shutil.copyfileobj(r, f)
    return dest

def resize_background(path, height):
    if height not in (0,720,1080,1440,2160):
        raise ValueError("Background resolution must be Original, 720p, 1080p, 1440p or 4K")
    if not height: return
    if PILImage is None: raise RuntimeError("Pillow is required to apply a background resolution limit")
    with PILImage.open(path) as original:
        image = original.convert("RGB")
        # A fit limit, never a crop or an upscale; retain the source aspect ratio.
        image.thumbnail((round(height*16/9),height), PILImage.Resampling.LANCZOS)
        image.save(path,"JPEG",quality=95)

def metadata_block(game_path, meta, assets, root, background_resolution=0):
    game_path = Path(game_path).resolve()
    rel = os.path.relpath(str(game_path), str(root)).replace("\\", "/")
    slug = safe_slug(game_path.stem)
    media = root / MEDIA_DIR / slug
    downloaded = {}
    warnings = []
    revision = str(time.time_ns())
    for key, url, filename in [
        ("background", assets.get("hero"), "background.jpg"),
        ("box_front", assets.get("cover"), "boxFront.jpg"),
        ("logo", assets.get("logo"), "logo.png"),
    ]:
        if url:
            try:
                asset_path = media / (Path(filename).stem + "-" + revision + Path(filename).suffix)
                if key == "background" and 0 < background_resolution <= 1080 and "images.igdb.com/igdb/image/upload/t_" in url:
                    size = "720p" if background_resolution<=720 else ("1080p" if background_resolution<=1080 else "1080p_2x")
                    url = re.sub(r"/t_[^/]+/", "/t_"+size+"/", url)
                fp = download(url, asset_path)
                if key == "background": resize_background(fp, background_resolution)
                if key == "logo" and PILImage is not None:
                    try:
                        with PILImage.open(fp) as im:
                            im = im.convert("RGBA")
                            # Pre-downsample oversized transparent logos with Lanczos.
                            # 1200x320 leaves Pegasus enough resolution for 4K while avoiding poor runtime minification.
                            im.thumbnail((1200, 320), PILImage.Resampling.LANCZOS)
                            im.save(fp, "PNG", optimize=True)
                    except Exception as e:
                        print(f"[Artwork] Logo resample skipped: {e}")
                downloaded[key] = os.path.relpath(str(fp), str(root)).replace("\\", "/")
            except Exception as error:
                warnings.append(f"Could not download {key}. Try applying its artwork again.")
                print(f"[Artwork] {key} download failed: {error}")
    if assets.get("logo") and PILImage is None:
        warnings.append("Logo saved, but Pillow is unavailable for resampling.")
    lines = [
        f"game: {meta.get('title') or game_path.stem}",
        f"file: {rel}",
        f"x-relay-file: {str(game_path)}",
        f"x-relay-id: igdb:{meta.get('id','')}",
        "x-relay-status: complete",
    ]
    if meta.get("developer"): lines.append("developer: " + meta["developer"])
    if meta.get("publisher"): lines.append("publisher: " + meta["publisher"])
    genres = meta.get("genres") or []
    if genres: lines.append("genre: " + ", ".join(genres))
    ts = meta.get("release_timestamp")
    if ts:
        lines.append("release: " + time.strftime("%Y-%m-%d", time.gmtime(ts)))
    summary = (meta.get("summary") or "").replace("\r"," ").replace("\n"," ").strip()
    if summary: lines.append("summary: " + summary)
    for key, val in downloaded.items():
        lines.append(f"assets.{key}: {val}")
    return "\n".join(lines), media, warnings

def status_registry_path():
    # Keep helper state beside the theme, rather than writing into the Pegasus root.
    return HERE / "relay-metadata-roots.json"

def known_metadata_roots():
    candidates = [status_registry_path()]
    try: candidates.append(find_config().parent / "relay-metadata-roots.json")
    except FileNotFoundError: pass
    roots = set()
    for path in candidates:
        try:
            if path.is_file(): roots.update(json.loads(path.read_text(encoding="utf-8")))
        except (OSError, ValueError): pass
    return roots

def remember_root(root):
    p = status_registry_path()
    roots = []
    try:
        if p.is_file(): roots = json.loads(p.read_text(encoding="utf-8"))
    except Exception: roots = []
    value = str(Path(root).resolve())
    if value not in roots:
        roots.append(value)
        p.write_text(json.dumps(roots, indent=2), encoding="utf-8")

def normalized_path(value):
    return str(value).replace("\\", "/").lower()

def curated_status(paths=None):
    result = {}
    roots = known_metadata_roots()

    # Crucial for existing curated libraries: discover their metadata roots from
    # executable paths supplied by the theme instead of relying on a registry
    # introduced in a later version.
    for game_path in (paths or []):
        if not game_path or game_path.startswith("steam:"): continue
        try:
            root = find_metadata_root(game_path)
            roots.add(str(root))
            remember_root(root)
        except Exception:
            pass

    for root_text in roots:
        root = Path(root_text)
        for game_path in load_generated(root).keys():
            result[game_path] = "complete"
            result[normalized_path(game_path)] = "complete"
    return result


def block_snapshot(block, root):
    fields = {}
    for line in block.splitlines():
        key, separator, value = line.partition(":")
        if separator: fields[key.strip()] = value.strip()
    assets = {}
    for api_key, field in [("background", "assets.background"), ("boxFront", "assets.box_front"), ("logo", "assets.logo")]:
        value = fields.get(field)
        assets[api_key] = (Path(root) / value).resolve().as_uri() if value else ""
    release=fields.get("release","")
    timestamp=0
    try: timestamp=calendar.timegm(time.strptime(release,"%Y-%m-%d")) if release else 0
    except ValueError: pass
    identity=fields.get("x-relay-id","").replace("igdb:","",1)
    return {"metadata": {"title":fields.get("game",""),"developer":fields.get("developer",""),
                         "publisher":fields.get("publisher",""),"genres":[x.strip() for x in fields.get("genre","").split(",") if x.strip()],
                         "id":identity,"release_timestamp":timestamp,"year":int(release[:4]) if timestamp else 0,
                         "summary":fields.get("summary","")},"assets":assets}

def curated_games(paths):
    result = {}
    roots = {Path(root) for root in known_metadata_roots()}
    roots.update(find_metadata_root(path) for path in paths if path and not path.startswith("steam:"))
    for root in roots:
        for path, block in load_generated(root).items():
            result[normalized_path(path)] = block_snapshot(block, root)
    return result


def apply_curated(payload):
    game_path = payload.get("path","")
    if not game_path: raise ValueError("Missing game path")
    resolution = payload.get("backgroundResolution",0)
    if type(resolution) is not int or resolution not in (0,720,1080,1440,2160):
        raise ValueError("Invalid background resolution")
    if resolution and PILImage is None:
        raise ValueError("Pillow is required for a background resolution limit; choose Original or install the helper dependencies")
    root = find_metadata_root(game_path)
    remember_root(root)
    generated = root / GENERATED_NAME
    if not generated.exists():
        generated.write_text("# Generated by Relay Metadata Helper. Safe to delete.\n", encoding="utf-8")
    blocks = load_generated(root)
    block, media, warnings = metadata_block(game_path, payload.get("metadata") or {}, payload.get("artwork") or {}, root, resolution)
    blocks[str(Path(game_path).resolve())] = block
    save_generated(root, blocks)
    snapshot = block_snapshot(block, root)
    snapshot["metadata"] = payload.get("metadata") or snapshot["metadata"]
    return {"ok": True, "metadata_file": str(root / GENERATED_NAME), "media_dir": str(media),
            "metadata": snapshot["metadata"], "assets": snapshot["assets"], "warnings": warnings}

def clear_curated(payload):
    game_path = str(Path(payload.get("path","")).resolve())
    if not game_path: raise ValueError("Missing game path")
    root = find_metadata_root(game_path)
    remember_root(root)
    generated = root / GENERATED_NAME
    if not generated.exists():
        generated.write_text("# Generated by Relay Metadata Helper. Safe to delete.\n", encoding="utf-8")
    blocks = load_generated(root)
    blocks.pop(game_path, None)
    save_generated(root, blocks)
    media = root / MEDIA_DIR / safe_slug(Path(game_path).stem)
    if media.exists(): shutil.rmtree(media, ignore_errors=True)
    return {"ok": True, "metadata_file": str(root / GENERATED_NAME)}



def steamgriddb_key():
    try:
        cfg = json.loads(find_config().read_text(encoding="utf-8-sig"))
        section = cfg.get("steamgriddb", {})
        return str(section.get("api_key", "")).strip()
    except Exception:
        return ""

def sgdb_get(path, key):
    url = "https://www.steamgriddb.com/api/v2/" + path
    req = Request(url, headers={"Authorization": "Bearer " + key, "User-Agent": "RelayPegasus/0.7.7"})
    try:
        with open_remote(req, timeout=15) as r:
            raw = r.read().decode("utf-8")
        payload = json.loads(raw)
        if payload.get("success") is False:
            raise RuntimeError("SteamGridDB API returned success=false: " + raw[:300])
        return payload.get("data", [])
    except HTTPError as e:
        detail = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"SteamGridDB HTTP {e.code} for {path}: {detail[:300]}")
    except URLError as e:
        raise RuntimeError(f"SteamGridDB network error for {path}: {e}")

def steamgriddb_artwork(title):
    key = steamgriddb_key()
    if not key:
        print("[SteamGridDB] No API key configured.")
        return None
    if not title:
        print("[SteamGridDB] No title supplied.")
        return None

    print(f"[SteamGridDB] Search: {title}")
    games = sgdb_get("search/autocomplete/" + quote(title, safe=""), key)
    if not games:
        print(f"[SteamGridDB] No game match for: {title}")
        return None

    norm = lambda x: re.sub(r"[^a-z0-9]+", "", str(x).lower())
    exact = [g for g in games if norm(g.get("name")) == norm(title)]
    game = exact[0] if exact else next((g for g in games if g.get("verified")), games[0])
    gid = game["id"]
    print(f"[SteamGridDB] Matched: {game.get('name')} ({gid})")

    heroes = sgdb_get(f"heroes/game/{gid}", key)
    grids = sgdb_get(f"grids/game/{gid}", key)
    logos = sgdb_get(f"logos/game/{gid}", key)

    def image(item, source):
        return {"id": item.get("id"), "url": item.get("url"), "width": item.get("width"),
                "height": item.get("height"), "source": source}

    # Prefer full-screen detail over panoramic Steam banners, then native pixel area.
    heroes.sort(key=lambda x: ((x.get("width") or 0)>=3840 and (x.get("height") or 0)>=2160, (x.get("height") or 0)>=1080, (x.get("width") or 0)*(x.get("height") or 0)), reverse=True)
    vertical = [x for x in grids if (x.get("height") or 0) > (x.get("width") or 0)]
    print(f"[SteamGridDB] Heroes: {len(heroes)}")
    print(f"[SteamGridDB] Covers: {len(vertical)} (from {len(grids)} grids)")
    print(f"[SteamGridDB] Logos: {len(logos)}")

    return {
        "game": {"id": gid, "name": game.get("name")},
        "hero": [image(x, "SteamGridDB hero") for x in heroes[:20] if x.get("url")],
        "cover": [image(x, "SteamGridDB grid") for x in vertical[:20] if x.get("url")],
        "logo": [image(x, "SteamGridDB logo") for x in logos[:20] if x.get("url")]
    }

def reload_pegasus():
    if os.name != "nt":
        return {"ok": False, "error": "Reload hotkey is currently Windows-only"}
    # Pegasus documents F5 as "reload its files". Send F5 to the active Pegasus window.
    import ctypes
    user32 = ctypes.windll.user32
    VK_F5 = 0x74
    KEYEVENTF_KEYUP = 0x0002
    user32.keybd_event(VK_F5, 0, 0, 0)
    time.sleep(0.05)
    user32.keybd_event(VK_F5, 0, KEYEVENTF_KEYUP, 0)
    return {"ok": True}

SETTINGS_SCHEMA = HERE.parent / "settings-schema.json"
SETTINGS_FILE = HERE.parent / "relay-settings.json"
settings_lock = threading.Lock()

def validate_theme_settings(payload):
    if not isinstance(payload, dict):
        raise ValueError("Settings must be a JSON object")
    schema = json.loads(SETTINGS_SCHEMA.read_text(encoding="utf-8"))
    payload = dict(payload)
    for mode in ("decode", "weave"):
        for suffix, legacy in (("HaloRadius", "glowRadius"), ("BloomIntensity", "glowIntensity")):
            if mode + suffix not in payload and legacy in payload:
                payload[mode + suffix] = payload[legacy]
    result = {}
    for key, spec in schema.items():
        value = payload.get(key, spec["default"])
        if spec["type"] == "framing":
            if not isinstance(value, dict) or len(value)>10000: raise ValueError("Invalid thumbnail framing")
            frames={}
            for name, frame in value.items():
                if not isinstance(name,str) or len(name)>4096 or not isinstance(frame,dict): raise ValueError("Invalid thumbnail frame")
                crop={}
                for axis, default, low, high in [("x",50,0,100),("y",50,0,100),("zoom",100,100,200)]:
                    amount=frame.get(axis,default)
                    if isinstance(amount,bool) or not isinstance(amount,(int,float)) or not math.isfinite(amount): raise ValueError("Invalid crop value")
                    crop[axis]=max(low,min(high,round(amount)))
                frames[name]=crop
            value=frames
        elif spec["type"] == "palette":
            if not isinstance(value,list) or len(value)>32: raise ValueError("Invalid saved colours")
            colours=[]
            colour_names=set()
            for colour in value:
                if not isinstance(colour,dict) or not isinstance(colour.get("name"),str) or not colour["name"].strip() or len(colour["name"])>32: raise ValueError("Invalid colour name")
                clean={"name":colour["name"].strip()}
                normalized=clean["name"].upper()
                if normalized=="CUSTOM" or normalized in colour_names: raise ValueError("Reserved or duplicate colour name")
                colour_names.add(normalized)
                for channel in ("red","green","blue"):
                    amount=colour.get(channel)
                    if isinstance(amount,bool) or not isinstance(amount,(int,float)) or not math.isfinite(amount): raise ValueError("Invalid colour channel")
                    clean[channel]=max(0,min(255,round(amount)))
                colours.append(clean)
            value=colours
        elif spec["type"] == "boolean":
            if not isinstance(value, bool): raise ValueError(f"Invalid boolean setting: {key}")
        else:
            if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
                raise ValueError(f"Invalid numeric setting: {key}")
            value = max(spec["min"], min(spec["max"], round(value)))
        result[key] = value
    if "animationLevel" not in payload:
        result["animationLevel"] = 0 if payload.get("animation") is False else 1
    result["animation"] = result["animationLevel"] > 0
    if "frostGlintMs" not in payload and isinstance(payload.get("frostGlintLength"),(int,float)) and not isinstance(payload["frostGlintLength"],bool): result["frostGlintMs"]=round(result["frostSharpMs"]*result["frostGlintLength"]/100)
    result["frostGlintMs"]=max(20,min(700,round(result["frostSharpMs"]*.4),result["frostGlintMs"]))
    if not result["overdrive"]: result["cardWidth"] = min(360,result["cardWidth"])
    builtins={"RELAY GREEN","CYAN","AMBER","WHITE","RED","CUSTOM"}
    additional=sum(c["name"].upper() not in builtins for c in result["savedColours"])
    result["accent"]=min(result["accent"],5+additional)
    result["schemaVersion"] = 2
    return result

def save_theme_settings(payload):
    settings = validate_theme_settings(payload)
    with settings_lock:
        temporary = SETTINGS_FILE.with_suffix(".json.tmp")
        temporary.write_text(json.dumps(settings, indent=2) + "\n", encoding="utf-8")
        os.replace(temporary, SETTINGS_FILE)
    return {"ok": True, "settings": settings, "file": SETTINGS_FILE.name}

def read_theme_settings():
    with settings_lock:
        exists = SETTINGS_FILE.is_file()
        payload = json.loads(SETTINGS_FILE.read_text(encoding="utf-8")) if exists else {}
    return {"ok": True, "exists": exists, "settings": validate_theme_settings(payload)}

class Handler(BaseHTTPRequestHandler):
    def send_json(self, status, payload):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        try:
            length = int(self.headers.get("Content-Length", "0"))
            payload = json.loads(self.rfile.read(length).decode("utf-8")) if length else {}
            req = urlparse(self.path)
            if req.path == "/theme-settings":
                try: return self.send_json(200, save_theme_settings(payload))
                except (ValueError, TypeError) as error: return self.send_json(400, {"error": str(error)})
            if req.path == "/apply":
                return self.send_json(200, apply_curated(payload))
            if req.path == "/clear":
                return self.send_json(200, clear_curated(payload))
            if req.path == "/reload":
                return self.send_json(200, reload_pegasus())
            return self.send_json(404, {"error":"not_found"})
        except Exception as e:
            return self.send_json(500, {"error": str(e)})

    def do_GET(self):
        req = urlparse(self.path)
        try:
            if req.path == "/theme-settings":
                return self.send_json(200, read_theme_settings())
            if req.path == "/health":
                return self.send_json(200, {"ok": provider is not None, "provider": "igdb", "error": startup_error})
            if req.path == "/status":
                paths = parse_qs(req.query).get("path", [])
                return self.send_json(200, {"status": curated_status(paths), "games": curated_games(paths)})
            if provider is None:
                return self.send_json(503, {"error": startup_error or "provider unavailable"})
            if req.path == "/search":
                q = parse_qs(req.query).get("q", [""])[0].strip()
                if not q: return self.send_json(400, {"error": "Search query is empty"})
                results = provider.search(q)
                if not results:
                    shorter = re.sub(r"(?i)\s*[:\-]?\s*(ultimate|deluxe|complete|definitive|gold|standard|collector.s)\s+edition.*$", "", q).strip()
                    if shorter and shorter != q: results = provider.search(shorter)
                return self.send_json(200, {"query": q, "provider": "igdb", "results": results})
            if req.path == "/game":
                gid = parse_qs(req.query).get("id", [""])[0]
                game = provider.game(gid)
                return self.send_json(200 if game else 404, {"provider": "igdb", "game": game})
            if req.path == "/artwork":
                qs = parse_qs(req.query)
                gid = qs.get("id", [""])[0]
                title = qs.get("title", [""])[0].strip()
                try:
                    sg = steamgriddb_artwork(title)
                    if sg and (sg["hero"] or sg["cover"] or sg["logo"]):
                        missing = [kind for kind in ("hero", "cover", "logo") if not sg[kind]]
                        if not any((x.get("width") or 0)>=3840 and (x.get("height") or 0)>=2160 for x in sg["hero"]): missing.append("high_resolution_hero")
                        if missing:
                            try:
                                fallback = provider.artwork(gid)
                                for kind in missing:
                                    if kind=="high_resolution_hero":
                                        existing={x.get("url") for x in sg["hero"]}
                                        sg["hero"] += [x for x in fallback.get("hero", []) if x.get("url") not in existing]
                                        sg["hero"].sort(key=lambda x: ((x.get("width") or 0)>=3840 and (x.get("height") or 0)>=2160, (x.get("height") or 0)>=1080, (x.get("width") or 0)*(x.get("height") or 0)), reverse=True)
                                    else: sg[kind] = fallback.get(kind, [])
                            except Exception as error:
                                print(f"[Artwork] Optional IGDB fallback failed; keeping SteamGridDB results: {error}")
                        print("[Artwork] Using SteamGridDB artwork.")
                        return self.send_json(200, {"provider": "steamgriddb", "artwork": sg})
                    print("[Artwork] SteamGridDB returned no usable artwork; falling back to IGDB.")
                except Exception as e:
                    print(f"[SteamGridDB] ERROR: {e}")
                    print("[Artwork] Falling back to IGDB.")
                fallback = provider.artwork(gid)
                print(f"[IGDB] Heroes: {len(fallback.get('hero', []))}, Covers: {len(fallback.get('cover', []))}, Logos: {len(fallback.get('logo', []))}")
                return self.send_json(200, {"provider": "igdb", "artwork": fallback})
            return self.send_json(404, {"error": "not_found"})
        except (HTTPError, URLError, RuntimeError, ValueError) as e:
            return self.send_json(502, {"error": str(e)})
        except Exception as e:
            return self.send_json(500, {"error": str(e)})

    def log_message(self, fmt, *args):
        print("[relay-metadata] " + fmt % args)

def pegasus_running():
    """Match the Pegasus executable belonging to this theme, not unrelated apps."""
    if os.name != "nt": return False
    import ctypes
    from ctypes import wintypes
    executable = next((parent / "pegasus-fe.exe" for parent in HERE.parents if (parent / "pegasus-fe.exe").is_file()), None)
    if executable is None: return False
    class ProcessEntry(ctypes.Structure):
        _fields_ = [("dwSize", wintypes.DWORD), ("cntUsage", wintypes.DWORD),
                    ("th32ProcessID", wintypes.DWORD), ("th32DefaultHeapID", ctypes.c_size_t),
                    ("th32ModuleID", wintypes.DWORD), ("cntThreads", wintypes.DWORD),
                    ("th32ParentProcessID", wintypes.DWORD), ("pcPriClassBase", wintypes.LONG),
                    ("dwFlags", wintypes.DWORD), ("szExeFile", wintypes.WCHAR * 260)]
    kernel = ctypes.WinDLL("kernel32", use_last_error=True)
    kernel.CreateToolhelp32Snapshot.argtypes = [wintypes.DWORD, wintypes.DWORD]
    kernel.CreateToolhelp32Snapshot.restype = wintypes.HANDLE
    kernel.Process32FirstW.argtypes = [wintypes.HANDLE, ctypes.POINTER(ProcessEntry)]
    kernel.Process32NextW.argtypes = [wintypes.HANDLE, ctypes.POINTER(ProcessEntry)]
    kernel.OpenProcess.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
    kernel.OpenProcess.restype = wintypes.HANDLE
    kernel.QueryFullProcessImageNameW.argtypes = [wintypes.HANDLE, wintypes.DWORD, wintypes.LPWSTR, ctypes.POINTER(wintypes.DWORD)]
    kernel.CloseHandle.argtypes = [wintypes.HANDLE]
    snapshot = kernel.CreateToolhelp32Snapshot(2, 0)
    if snapshot == wintypes.HANDLE(-1).value: return False
    try:
        entry = ProcessEntry(); entry.dwSize = ctypes.sizeof(entry)
        more = kernel.Process32FirstW(snapshot, ctypes.byref(entry))
        while more:
            if entry.szExeFile.lower() == "pegasus-fe.exe":
                handle = kernel.OpenProcess(0x1000, False, entry.th32ProcessID)
                if handle:
                    try:
                        buffer = ctypes.create_unicode_buffer(32768); size = wintypes.DWORD(len(buffer))
                        if kernel.QueryFullProcessImageNameW(handle, 0, buffer, ctypes.byref(size)):
                            if normalized_path(buffer.value) == normalized_path(executable): return True
                    finally: kernel.CloseHandle(handle)
            more = kernel.Process32NextW(snapshot, ctypes.byref(entry))
        return False
    finally: kernel.CloseHandle(snapshot)

def watch_pegasus(server, is_running=None, sleep=None, startup_grace=15):
    is_running = is_running or pegasus_running
    sleep = sleep or time.sleep
    seen = False
    deadline = time.monotonic() + startup_grace
    while True:
        running = is_running()
        if running: seen = True
        elif seen or time.monotonic() >= deadline:
            print("Pegasus closed; shutting down its metadata helper.")
            server.shutdown(); return
        sleep(0.5)

if __name__ == "__main__":
    managed = "--managed" in sys.argv
    if managed:
        sys.stdout = open(HERE / "helper-output.log", "a", encoding="utf-8", buffering=1)
        sys.stderr = open(HERE / "helper-error.log", "a", encoding="utf-8", buffering=1)
    try:
        server = ThreadingHTTPServer((HOST, PORT), Handler)
    except OSError as error:
        if getattr(error, "winerror", None) == 10048 or getattr(error, "errno", None) == 98:
            print("Metadata helper is already running."); sys.exit(0)
        raise
    server.daemon_threads = True
    print(f"Relay Metadata Helper v0.10.5 â€” http://{HOST}:{PORT}")
    if provider: print(f"IGDB provider active. Config: {provider.config_path}")
    else: print("CONFIG ERROR:", startup_error)
    if managed: threading.Thread(target=watch_pegasus, args=(server,), daemon=True).start()
    try: server.serve_forever(poll_interval=0.2)
    finally: server.server_close()

