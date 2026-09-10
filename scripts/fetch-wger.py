#!/usr/bin/env python3
"""Fotos de técnica de los ejercicios del catálogo, desde la API abierta de wger.de.

Descarga la imagen principal de cada ejercicio (licencias CC-BY-SA), la deja
en Assets.xcassets/Technique/<slug>.imageset (JPEG, 600 px de lado) y genera
FitnessApp/TechniquePhotos.swift con el nombre del asset, el autor y la
licencia de cada una (la app los muestra como atribución).

  python3 scripts/fetch-wger.py

Las imágenes generadas por IA se descartan. Idempotente.
"""
import json, os, re, subprocess, tempfile, unicodedata, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, 'FitnessApp', 'Assets.xcassets', 'Technique')
OUT = os.path.join(ROOT, 'FitnessApp', 'TechniquePhotos.swift')

# Ejercicio del catálogo → id de wger (elegidos a mano por parecido).
MAP = {
    'Press de banca': 73, 'Press inclinado mancuernas': 537, 'Aperturas': 238, 'Fondos': 194, 'Flexiones': 1551,
    'Dominadas': 475, 'Remo con barra': 83, 'Jalón al pecho': 158, 'Remo en máquina': 1117, 'Peso muerto': 184,
    'Press militar': 566, 'Elevaciones laterales': 348, 'Elevaciones frontales': 256, 'Pájaros': 487,
    'Curl con barra': 91, 'Curl con mancuernas': 92, 'Curl martillo': 272, 'Press francés': 246,
    'Extensiones en polea': 805, 'Fondos en banco': 197, 'Sentadilla': 1801, 'Prensa': 371,
    'Extensión de cuádriceps': 369, 'Curl femoral': 364, 'Zancadas': 984, 'Gemelos de pie': 622,
    'Hip thrust': 1642, 'Abducción de cadera': 1748, 'Puente de glúteo': 265, 'Plancha': 458, 'Crunch': 167,
    'Elevación de piernas': 377, 'Russian twist': 1193, 'Cinta de correr': 1615, 'Bicicleta estática': 1618,
}
LICENSES = {1: 'CC BY-SA 3.0', 2: 'CC BY-SA 4.0', 3: 'CC0', 4: 'CC BY 4.0'}

def slug(s):
    s = unicodedata.normalize('NFKD', s).encode('ascii', 'ignore').decode()
    return re.sub(r'[^a-z0-9]+', '-', s.lower()).strip('-')

def get(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'ChamaFit/2.0 (fetch-wger)'})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()

os.makedirs(ASSETS, exist_ok=True)
with open(os.path.join(ASSETS, 'Contents.json'), 'w') as f:
    json.dump({'info': {'author': 'xcode', 'version': 1}, 'properties': {'provides-namespace': True}}, f, indent=2)

entries = []
for name, wid in MAP.items():
    info = json.loads(get(f'https://wger.de/api/v2/exerciseinfo/{wid}/'))
    imgs = [i for i in info.get('images', []) if not i.get('is_ai_generated')]
    if not imgs:
        print('sin foto:', name); continue
    img = next((i for i in imgs if i.get('is_main')), imgs[0])
    s = slug(name)
    folder = os.path.join(ASSETS, f'{s}.imageset')
    os.makedirs(folder, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=os.path.splitext(img['image'])[1]) as tmp:
        tmp.write(get(img['image'])); tmp.flush()
        subprocess.run(['sips', '-s', 'format', 'jpeg', '-s', 'formatOptions', '80', '-Z', '600', tmp.name,
                        '--out', os.path.join(folder, f'{s}.jpg')], check=True, capture_output=True)
    with open(os.path.join(folder, 'Contents.json'), 'w') as f:
        json.dump({'images': [{'filename': f'{s}.jpg', 'idiom': 'universal'}], 'info': {'author': 'xcode', 'version': 1}}, f, indent=2)
    author = (img.get('license_author') or info.get('license_author') or 'wger.de').strip() or 'wger.de'
    entries.append((name, f'Technique/{s}', author, LICENSES.get(img.get('license'), 'CC BY-SA')))
    print('ok:', name, '←', author)

with open(OUT, 'w') as f:
    f.write('//\n//  TechniquePhotos.swift\n//  ChamaFit\n//\n//  GENERADO por scripts/fetch-wger.py: fotos de técnica de wger.de con su\n'
            '//  autor y licencia. No editar a mano.\n//\n\nimport Foundation\n\n'
            'enum TechniquePhotos {\n    struct Photo { let asset: String; let author: String; let license: String }\n\n'
            '    static let byName: [String: Photo] = [\n')
    for name, asset, author, lic in entries:
        f.write(f'        "{name}": Photo(asset: "{asset}", author: {json.dumps(author, ensure_ascii=False)}, license: "{lic}"),\n')
    f.write('    ]\n}\n')
print(f'{len(entries)} fotos')
