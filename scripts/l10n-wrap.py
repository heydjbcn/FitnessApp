#!/usr/bin/env python3
"""Prepara el código para traducirse (es → en, ca).

1. Los literales con interpolación que se enseñan pero no pasan por un
   inicializador de SwiftUI que ya localiza (Text, Label, Button…) se
   envuelven en String(localized: "…"), que Xcode extrae con %lld/%@.
2. `Text(variable)` pasa a `Text((variable).loc)`: se traduce en tiempo de
   ejecución si hay traducción (la clave es el texto en español).
3. Saca a scripts/l10n-plain.json los literales sin interpolación que se
   ven en pantalla, para meterlos a mano en el catálogo.

Uso: scripts/l10n-wrap.py [--dry] ficheros…
"""
import json, re, sys, pathlib

SPANISH = re.compile(r"[a-záéíóúñü]{2,}", re.I)
SKIP_BEFORE = re.compile(
    r"(accessibilityIdentifier\(|forKey:|systemImage:|systemName:|symbol:|icon:\s*$|Image\(|named:|imageName|"
    r"URL\(string:|dateFormat\s*=|NSPredicate\(format:|hasPrefix\(|hasSuffix\(|contains\(|==\s*$|!=\s*$|"
    r"\bcase\s+$|\bcase\s+\.\w+\s*=\s*$|Keychain|userDefaults\.|defaults\.|UserDefaults|Logger|print\(|fatalError\(|"
    r"precondition|recordType:|CKRecord|forInfoDictionaryKey:|rawValue:|identifier:|withIdentifier:|"
    r"format:\s*$|String\(localized:\s*$|LocalizedStringKey\(\s*$|verbatim:\s*$|\.asset|asset:|font\(|custom\(|"
    r"accessibilityValue\(|replacingOccurrences\(of:|components\(separatedBy:|split\(separator:|"
    r"setValue\(|forHTTPHeaderField|httpMethod|\"model\"|request\(\")"
)
# Inicializadores de SwiftUI cuyo primer argumento ya es LocalizedStringKey.
LOCALIZED_OPENERS = re.compile(
    r"(\bText\(|\bLabel\(|\bButton\(|\bToggle\(|\bStepper\(|\bPicker\(|\bSection\(|\bTextField\(|\bSecureField\(|"
    r"\.navigationTitle\(|\.alert\(|\.confirmationDialog\(|\bMenu\(|\bLink\(|\bDatePicker\(|\bShareLink\(item:\s*[^,]+,\s*message:\s*Text\()\s*$"
)
TEXT_CALL = re.compile(r"\bText\(")


def scan_strings(src):
    """Devuelve (inicio, fin, contenido, interpolado) de los literales de primer nivel."""
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if src.startswith("//", i):
            i = src.find("\n", i)
            if i < 0: break
            continue
        if src.startswith("/*", i):
            j = src.find("*/", i)
            i = n if j < 0 else j + 2
            continue
        if src.startswith('"""', i):
            j = src.find('"""', i + 3)
            i = n if j < 0 else j + 3
            continue
        if c == '"':
            start = i
            i += 1
            interp = False
            while i < n and src[i] != '"':
                if src[i] == "\\":
                    if i + 1 < n and src[i + 1] == "(":
                        interp = True
                        depth, i = 1, i + 2
                        while i < n and depth:
                            if src[i] == '"':
                                # literal anidado dentro de la interpolación
                                i += 1
                                while i < n and src[i] != '"':
                                    i += 2 if src[i] == "\\" else 1
                            elif src[i] == "(":
                                depth += 1
                            elif src[i] == ")":
                                depth -= 1
                            i += 1
                        continue
                    i += 2
                    continue
                if src[i] == "\n":
                    break
                i += 1
            end = i + 1
            out.append((start, end, src[start + 1:i], interp))
            i = end
            continue
        i += 1
    return out


def user_facing(content):
    text = re.sub(r"\\\((?:[^()]|\([^()]*\))*\)", " ", content)
    if not SPANISH.search(text):
        return False
    interp = "\\(" in content
    words = re.findall(r"[a-záéíóúñü]{3,}", text, re.I)
    # "Semana \(n)", "\(n) sesiones": una palabra con una variable ya es una frase.
    if interp and re.search(r"[._#/:=\[\]\-]", text) and not re.search(r"[a-záéíóúñ]{2,}\s+[a-záéíóúñ]{2,}", text, re.I):
        return False   # identificadores: "set.\(n)", "reminder-\(d)"
    if interp and words:
        return True
    solid = re.sub(r"\\\((?:[^()]|\([^()]*\))*\)", "X", content)
    return (" " in solid.strip()) or bool(re.search(r"[áéíóúñ¿¡]", text, re.I))


def balanced_arg(src, open_paren):
    """Índice del paréntesis que cierra el que abre en open_paren."""
    depth, i, n = 0, open_paren, len(src)
    while i < n:
        c = src[i]
        if c == '"':
            i += 1
            while i < n and src[i] != '"':
                if src[i] == "\\" and i + 1 < n and src[i + 1] == "(":
                    d, i = 1, i + 2
                    while i < n and d:
                        if src[i] == "(": d += 1
                        elif src[i] == ")": d -= 1
                        i += 1
                    continue
                i += 2 if src[i] == "\\" else 1
        elif c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def process(path, dry, plain):
    src = path.read_text()
    edits = []  # (start, end, replacement)
    for start, end, content, interp in scan_strings(src):
        if not user_facing(content):
            continue
        line_start = src.rfind("\n", 0, start) + 1
        before = src[line_start:start]
        after = src[end:end + 3]
        if SKIP_BEFORE.search(before) or after.lstrip().startswith(":"):
            continue
        # `case lunes = "Lunes"` (valor guardado) o `case "substitute":` (patrón): no se tocan.
        if re.fullmatch(r"\s*case\s+(\.?\w+\s*=\s*)?", before) or re.search(r"\bcase\s+\w+\s*=\s*$", before):
            continue
        if not interp:
            plain.add(content)
            continue
        if LOCALIZED_OPENERS.search(before):
            continue
        edits.append((start, end, f'String(localized: {src[start:end]})'))
    # Text(variable) → Text((variable).loc)
    for m in TEXT_CALL.finditer(src):
        open_i = m.end() - 1
        close_i = balanced_arg(src, open_i)
        if close_i < 0:
            continue
        arg = src[open_i + 1:close_i].strip()
        if not arg or arg.startswith('"') or arg.startswith("verbatim:") or arg.startswith("LocalizedStringKey") \
           or arg.startswith("String(localized") or "," in arg and not arg.startswith("(") \
           or arg.endswith(".loc") or arg.startswith("(try?") or "AttributedString" in arg or arg.startswith("."):
            continue
        # sin literales dentro (esos ya van por el catálogo)
        if '"' in arg:
            continue
        if any(s <= open_i + 1 < e for s, e, _ in edits):
            continue
        edits.append((open_i + 1, close_i, f"({src[open_i + 1:close_i]}).loc"))
    if not edits:
        return 0
    edits.sort(key=lambda e: e[0], reverse=True)
    out = src
    for s, e, r in edits:
        out = out[:s] + r + out[e:]
    if not dry:
        path.write_text(out)
    return len(edits)


def main():
    dry = "--dry" in sys.argv
    files = [pathlib.Path(a) for a in sys.argv[1:] if not a.startswith("--")]
    plain = set()
    total = 0
    for f in files:
        n = process(f, dry, plain)
        if n:
            print(f"{f.name}: {n}")
        total += n
    out = pathlib.Path(__file__).with_name("l10n-plain.json")
    old = set(json.loads(out.read_text())) if out.exists() else set()
    out.write_text(json.dumps(sorted(old | plain), ensure_ascii=False, indent=1))
    print(f"total cambios: {total} · literales sin interpolar: {len(plain)}")


main()
