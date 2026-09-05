#!/usr/bin/env bash
# Exporte un .drawio en PNG avec le diagramme embarqué (le PNG se rouvre et se
# ré-édite dans draw.io sans le .drawio d'origine), puis vérifie que l'export
# a réellement produit ce qu'il annonce.
#
# Usage : export.sh [chemin/vers/diagramme.drawio]
set -euo pipefail

SRC="${1:-docs/architecture/class-diagram.drawio}"
[ -f "$SRC" ] || { echo "Introuvable : $SRC" >&2; exit 1; }

# Le sandbox flatpak ne voit pas /tmp de l'hôte : entrée ET sortie doivent
# vivre sous $HOME, sinon l'export échoue en silence tout en affichant une
# ligne qui ressemble à un succès.
case "$(realpath "$SRC")" in
  "$HOME"/*) ;;
  *) echo "Le fichier doit être sous \$HOME (sandbox flatpak) : $SRC" >&2; exit 1 ;;
esac

OUT="${SRC%.drawio}.png"

# xvfb : sans écran, draw.io meurt sur une init GPU EGL/ANGLE sans rien écrire.
# Les erreurs dbus/vaInitialize dans la sortie sont le bruit normal du sandbox.
xvfb-run -a flatpak run com.jgraph.drawio.desktop \
  -x -f png -e -b 20 -o "$OUT" "$SRC" 2>&1 |
  grep -viE "ERROR:dbus|vaInitialize|libva" || true

[ -f "$OUT" ] || { echo "Aucun PNG produit" >&2; exit 1; }

# L'export peut "réussir" sans embarquer la métadonnée : on le vérifie plutôt
# que de le supposer.
python3 - "$OUT" <<'PY'
import struct, sys, zlib
data = open(sys.argv[1], 'rb').read()
pos = 8
while pos < len(data):
    length = struct.unpack('>I', data[pos:pos + 4])[0]
    kind = data[pos + 4:pos + 8]
    if kind in (b'zTXt', b'tEXt'):
        key = data[pos + 8:pos + 8 + length].split(b'\x00', 1)[0]
        if key == b'mxGraphModel':
            print(f"OK — {sys.argv[1]} embarque le diagramme éditable")
            sys.exit(0)
    if kind == b'IEND':
        break
    pos += 12 + length
sys.exit("ÉCHEC — PNG sans métadonnée : il ne serait pas ré-éditable")
PY

echo "→ $OUT"
