#!/usr/bin/env python3
"""Déchiffre un fichier de sauvegarde TenK (.tenkbak) et affiche son contenu en JSON.

Usage : python3 tool/open_backup.py <fichier.tenkbak> [mot de passe] > sauvegarde.json
Sans mot de passe en argument, il est demandé au clavier (il n'apparaît pas à l'écran).
Dépendance : pip install cryptography

Le format est celui de `BackupEnvelope` (lib/state/backup_archive.dart) : `TENKBAK`, version
(1 octet), itérations (4 octets, grand-boutiste), sel (16), nonce (12), puis le JSON gzippé
chiffré en AES-256-GCM suivi de son étiquette (16). L'en-tête de 28 octets est authentifié.
La clef vient du mot de passe par PBKDF2-HMAC-SHA256.

Les valeurs de `players`, `paused` et `finished` sont le contenu brut des fichiers de l'app :
du texte, à décoder à son tour (json.loads) pour les fiches joueurs.
"""
import getpass
import gzip
import hashlib
import json
import sys

from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

MAGIC = b"TENKBAK"
HEADER = len(MAGIC) + 1 + 4 + 16  # 28
NONCE = 12
TAG = 16


def open_backup(data: bytes, password: str) -> dict:
    if len(data) < HEADER + NONCE + TAG or data[: len(MAGIC)] != MAGIC:
        raise SystemExit("Ce fichier n'est pas une sauvegarde de TenK.")
    if data[len(MAGIC)] != 1:
        raise SystemExit("Version de sauvegarde inconnue : %d." % data[len(MAGIC)])
    header = data[:HEADER]
    iterations = int.from_bytes(data[8:12], "big")
    salt = data[12:HEADER]
    nonce = data[HEADER : HEADER + NONCE]
    key = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, iterations, 32)
    try:
        clear = AESGCM(key).decrypt(nonce, data[HEADER + NONCE :], header)
    except InvalidTag:
        raise SystemExit("Mot de passe incorrect, ou fichier modifié.")
    return json.loads(gzip.decompress(clear))


def main() -> None:
    if len(sys.argv) not in (2, 3):
        raise SystemExit(__doc__)
    password = sys.argv[2] if len(sys.argv) == 3 else getpass.getpass("Mot de passe : ")
    with open(sys.argv[1], "rb") as f:
        archive = open_backup(f.read(), password)
    print(json.dumps(archive, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
