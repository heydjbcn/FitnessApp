#!/usr/bin/env python3
"""Crea (o renueva) los perfiles ad hoc de ChamaFit por la API de App Store Connect.

Registra el bundle ID del widget si falta, activa HealthKit donde toca, mete en
el perfil TODOS los iPhones y Apple Watch habilitados del equipo y deja los
tres .mobileprovision instalados en ~/Library/MobileDevice/Provisioning Profiles.

Credenciales: ~/.appstoreconnect/config.json {key_id, issuer_id} y la clave
~/.appstoreconnect/private_keys/AuthKey_<key_id>.p8 (fuera del repo).
Necesita: pip3 install pyjwt requests cryptography

Un iPhone nuevo = registrar su UDID (Certificates, Identifiers & Profiles ▸
Devices, o `--add-device NOMBRE UDID`) y volver a ejecutar esto + build-adhoc.sh.
"""
import base64, json, os, sys, time
import jwt, requests

CFG = json.load(open(os.path.expanduser('~/.appstoreconnect/config.json')))
KEY = open(os.path.expanduser(f"~/.appstoreconnect/private_keys/AuthKey_{CFG['key_id']}.p8")).read()
TOKEN = jwt.encode({'iss': CFG['issuer_id'], 'iat': int(time.time()), 'exp': int(time.time()) + 1100,
                    'aud': 'appstoreconnect-v1'}, KEY, algorithm='ES256', headers={'kid': CFG['key_id']})
H = {'Authorization': f'Bearer {TOKEN}', 'Content-Type': 'application/json'}
B = 'https://api.appstoreconnect.apple.com/v1'

PROFILES = [('Mauri.FitnessApp', 'ChamaFit AdHoc'),
            ('Mauri.FitnessApp.watchkitapp', 'ChamaFit Watch AdHoc'),
            ('Mauri.FitnessApp.ChamaFitWidgets', 'ChamaFit Widgets AdHoc'),
            ('Mauri.FitnessApp.watchkitapp.ChamaFitWatchWidgets', 'ChamaFit Watch Widgets AdHoc')]

def get(p):
    r = requests.get(B + p, headers=H); r.raise_for_status(); return r.json()
def post(p, body):
    r = requests.post(B + p, headers=H, json=body)
    if r.status_code >= 400: sys.exit(f'ERROR {p}: {r.text[:400]}')
    return r.json()
def delete(p): requests.delete(B + p, headers=H)

if len(sys.argv) == 4 and sys.argv[1] == '--add-device':
    post('/devices', {'data': {'type': 'devices', 'attributes': {'name': sys.argv[2], 'udid': sys.argv[3], 'platform': 'IOS'}}})
    print('registrado', sys.argv[2])

ids = {b['attributes']['identifier']: b['id'] for b in get('/bundleIds?limit=200')['data']}
for bid, name in [('Mauri.FitnessApp.ChamaFitWidgets', 'ChamaFit Widgets'),
                  ('Mauri.FitnessApp.watchkitapp.ChamaFitWatchWidgets', 'ChamaFit Watch Widgets')]:
    if bid not in ids:
        ids[bid] = post('/bundleIds', {'data': {'type': 'bundleIds', 'attributes': {'identifier': bid, 'name': name, 'platform': 'IOS'}}})['data']['id']
        print('bundle ID registrado:', bid)

for bid in ['Mauri.FitnessApp', 'Mauri.FitnessApp.watchkitapp']:
    caps = [c['attributes']['capabilityType'] for c in get(f'/bundleIds/{ids[bid]}/bundleIdCapabilities')['data']]
    if 'HEALTHKIT' not in caps:
        post('/bundleIdCapabilities', {'data': {'type': 'bundleIdCapabilities', 'attributes': {'capabilityType': 'HEALTHKIT'},
              'relationships': {'bundleId': {'data': {'type': 'bundleIds', 'id': ids[bid]}}}}})
        print('HealthKit activado en', bid)

certs = [c for c in get('/certificates?limit=50')['data'] if c['attributes']['certificateType'] in ('IOS_DISTRIBUTION', 'DISTRIBUTION')]
certs.sort(key=lambda c: c['attributes']['expirationDate'], reverse=True)
cert_id = certs[0]['id']

devices = [d for d in get('/devices?limit=200')['data']
           if d['attributes']['status'] == 'ENABLED' and d['attributes']['deviceClass'] in ('IPHONE', 'APPLE_WATCH')]
print(f'{len(devices)} dispositivos:', ', '.join(d['attributes']['name'] for d in devices))

existing = {p['attributes']['name']: p['id'] for p in get('/profiles?limit=200')['data']}
folder = os.path.expanduser('~/Library/MobileDevice/Provisioning Profiles')
os.makedirs(folder, exist_ok=True)
for bid, name in PROFILES:
    if name in existing: delete(f'/profiles/{existing[name]}')
    a = post('/profiles', {'data': {'type': 'profiles', 'attributes': {'name': name, 'profileType': 'IOS_APP_ADHOC'},
             'relationships': {'bundleId': {'data': {'type': 'bundleIds', 'id': ids[bid]}},
                               'certificates': {'data': [{'type': 'certificates', 'id': cert_id}]},
                               'devices': {'data': [{'type': 'devices', 'id': d['id']} for d in devices]}}}})['data']['attributes']
    open(os.path.join(folder, f"{a['uuid']}.mobileprovision"), 'wb').write(base64.b64decode(a['profileContent']))
    print('perfil', name, a['profileState'])
