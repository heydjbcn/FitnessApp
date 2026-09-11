#!/usr/bin/env python3
"""Comprueba los vídeos de técnica (oEmbed de YouTube) y regenera
FitnessApp/ExerciseVideos.swift con los que siguen vivos.

  scripts/check-videos.py          # comprueba y regenera
  scripts/check-videos.py --dry    # solo comprueba

Fuente: scripts/videos.json  {"Nombre": {"url": ..., "title": ..., "channel": ...}}
Un enlace muerto se queda fuera: la ficha cae a una búsqueda en YouTube.
"""
import json, sys, pathlib, urllib.request, urllib.parse, re
from concurrent.futures import ThreadPoolExecutor

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "scripts" / "videos.json"
OUT = ROOT / "FitnessApp" / "ExerciseVideos.swift"
CATALOG = ROOT / "FitnessApp" / "ExerciseCatalog.swift"

def alive(url):
    q = "https://www.youtube.com/oembed?format=json&url=" + urllib.parse.quote(url, safe="")
    try:
        with urllib.request.urlopen(q, timeout=15) as r:
            return r.status == 200
    except Exception:
        return False

def main():
    videos = json.loads(SRC.read_text())
    names = re.findall(r'CatalogExercise\(name: "([^"]+)"', CATALOG.read_text())
    missing = [n for n in names if not (videos.get(n) or {}).get("url")]
    items = [(n, v["url"]) for n, v in videos.items() if v.get("url")]
    with ThreadPoolExecutor(8) as pool:
        ok = dict(zip([n for n, _ in items], pool.map(lambda it: alive(it[1]), items)))
    dead = [n for n, good in ok.items() if not good]
    print(f"{len(items)} enlaces · {len(items) - len(dead)} vivos · {len(dead)} muertos · {len(missing)} ejercicios sin vídeo")
    for n in dead: print("  ✗ muerto:", n, videos[n]["url"])
    for n in missing: print("  · sin vídeo:", n)
    if "--dry" in sys.argv: return
    lines = [f'        "{n}": "{u}",' for n, u in sorted(items) if ok[n] and n in names]
    text = OUT.read_text()
    body = "static let byName: [String: String] = [\n" + "\n".join(lines) + "\n    ]"
    text = re.sub(r"static let byName: \[String: String\] = \[.*?\n    \]|static let byName: \[String: String\] = \[:\]", body, text, flags=re.S)
    OUT.write_text(text)
    print(f"✓ {OUT.relative_to(ROOT)} con {len(lines)} vídeos")

main()
