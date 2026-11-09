#!/usr/bin/env python3
"""generate.py çıktısını Firebase'e yükler.

Gereken: pip install firebase-admin
Kullanım:
  python3 upload_firebase.py --key /yol/serviceAccount.json --bucket <proje>.firebasestorage.app

Yüklenenler:
  Firestore  packs/{packId}         paket listesi (manifest)
  Firestore  dailies/{yyyy-MM-dd}   günlük bulmacalar (bulmaca + kelimeler)
  Firestore  words/{wordId}         soru havuzu (yönetim için; uygulama okumaz)
  Storage    packs/{id}_v{n}.json.gz  paket içerikleri
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / "out"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--key", required=True, help="Firebase hizmet hesabı JSON dosyası")
    ap.add_argument("--bucket", required=True, help="Storage bucket adı")
    ap.add_argument("--dry-run", action="store_true", help="Sadece ne yükleneceğini yaz")
    args = ap.parse_args()

    packs = json.loads((OUT / "firestore" / "packs.json").read_text(encoding="utf-8"))
    dailies = json.loads((OUT / "firestore" / "dailies.json").read_text(encoding="utf-8"))
    starter = HERE.parent.parent / "Cengelish/AppCore/ContentKit/Sources/Resources/starter.json"
    words = {w["id"]: w for w in json.loads(starter.read_text(encoding="utf-8"))["words"]}
    files = sorted((OUT / "storage" / "packs").glob("*.json.gz"))
    print(f"{len(packs)} paket, {len(dailies)} günlük bulmaca, {len(files)} dosya")
    if args.dry_run:
        return

    import firebase_admin
    from firebase_admin import credentials, firestore, storage

    firebase_admin.initialize_app(credentials.Certificate(args.key), {"storageBucket": args.bucket})
    db = firestore.client()
    bucket = storage.bucket()

    for path in files:
        blob = bucket.blob(f"packs/{path.name}")
        blob.upload_from_filename(str(path), content_type="application/gzip")
        print("Storage:", blob.name)

    batch = db.batch()
    for pack in packs:
        batch.set(db.collection("packs").document(pack["id"]), pack)
    for daily in dailies:
        batch.set(db.collection("dailies").document(daily["date"]), daily)
    batch.commit()
    print("Firestore: packs + dailies")

    words_batch = db.batch()
    for count, (wid, word) in enumerate(words.items(), start=1):
        words_batch.set(db.collection("words").document(wid), word)
        if count % 400 == 0:
            words_batch.commit()
            words_batch = db.batch()
    words_batch.commit()
    print(f"Firestore: {len(words)} kelime")


if __name__ == "__main__":
    main()
