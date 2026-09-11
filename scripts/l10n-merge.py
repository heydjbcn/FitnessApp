#!/usr/bin/env python3
"""Mete las traducciones (en, ca) en los catálogos .xcstrings.

  scripts/l10n-merge.py KEYS.json TRAD1.json [TRAD2.json …]

KEYS.json: {"extracted": {"FitnessApp/Localizable.xcstrings": [{"id","source"}…], …},
            "manual": [literales sin interpolar de la app]}
TRAD*.json: {"clave en español": {"en": "…", "ca": "…"}}
Además, scripts/l10n-infoplist.json con las traducciones de los permisos.
"""
import json, re, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
MARK = re.compile(r"%(?:\d+\$)?(?:lld|ld|lf|d|@|f|%)")


def markers(s):
    return sorted(m.replace("1$", "").replace("2$", "").replace("3$", "").replace("4$", "") for m in MARK.findall(s))


def load_translations(paths):
    t = {}
    for p in paths:
        t.update(json.loads(pathlib.Path(p).read_text()))
    return t


def unit(value):
    return {"stringUnit": {"state": "translated", "value": value}}


def build(keys, trans, catalog_path, info_plist=None, shortcuts=False):
    path = ROOT / catalog_path
    cat = json.loads(path.read_text()) if path.exists() else {"sourceLanguage": "es", "strings": {}, "version": "1.0"}
    strings = cat.setdefault("strings", {})
    missing, bad = [], []
    for k in keys:
        kid, source = k["id"], k.get("source", k["id"])
        entry = strings.setdefault(kid, {})
        if info_plist is not None:
            tr = info_plist.get(kid) or info_plist.get(source)
            if not tr:
                continue
        else:
            tr = trans.get(kid) or trans.get(source)
        if not tr:
            missing.append(kid)
            continue
        locs = entry.setdefault("localizations", {})
        for lang in ("en", "ca"):
            v = tr.get(lang)
            if not v:
                continue
            if info_plist is None and markers(v) != markers(kid):
                bad.append((kid, lang, v))
                continue
            if shortcuts:
                locs[lang] = {"stringSet": {"state": "translated", "values": [v]}}
            else:
                locs[lang] = unit(v)
        if not locs:
            entry.pop("localizations", None)
    path.write_text(json.dumps(cat, ensure_ascii=False, indent=2, sort_keys=True) + "\n")
    return missing, bad


def main():
    keys = json.loads(pathlib.Path(sys.argv[1]).read_text())
    trans = load_translations(sys.argv[2:])
    info = json.loads((ROOT / "scripts" / "l10n-infoplist.json").read_text())
    ext = keys["extracted"]
    report = {}
    app_keys = ext.get("FitnessApp/Localizable.xcstrings", []) + [{"id": m, "source": m} for m in keys["manual"]]
    # Todo lo traducido entra en el catálogo de la app (lo que llega por variables se busca en tiempo de ejecución).
    seen = {k["id"] for k in app_keys}
    app_keys += [{"id": t, "source": t} for t in trans if t not in seen and not t.startswith("NS") and "${applicationName}" not in t]
    report["app"] = build(app_keys, trans, "FitnessApp/Localizable.xcstrings")
    report["shortcuts"] = build(ext.get("FitnessApp/AppShortcuts.xcstrings", []), trans, "FitnessApp/AppShortcuts.xcstrings", shortcuts=True)
    report["infoplist"] = build(ext.get("FitnessApp/InfoPlist.xcstrings", []), trans, "FitnessApp/InfoPlist.xcstrings", info_plist=info)
    report["widgets"] = build(ext.get("ChamaFitWidgets/Localizable.xcstrings", []), trans, "ChamaFitWidgets/Localizable.xcstrings")
    report["watch"] = build(ext.get("WatchApp/Localizable.xcstrings", []), trans, "WatchApp/Localizable.xcstrings")
    report["watchwidgets"] = build(ext.get("ChamaFitWatchWidgets/Localizable.xcstrings", []), trans, "ChamaFitWatchWidgets/Localizable.xcstrings")
    report["watchinfo"] = build(ext.get("WatchApp/AppFit Watch-InfoPlist.xcstrings", []), trans, "WatchApp/InfoPlist.xcstrings", info_plist=info)
    for name, (missing, bad) in report.items():
        print(f"{name}: faltan {len(missing)} · marcadores mal {len(bad)}")
        for m in missing[:8]: print("   falta:", m[:90])
        for b in bad[:8]: print("   mal:", b[0][:60], "|", b[1], "|", b[2][:60])


main()
