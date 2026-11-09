#!/usr/bin/env python3
"""generate.py çıktısını Firestore'a yükler (ücretsiz Spark planında çalışır; Storage gerekmez).

Gereken: pip install firebase-admin
Kullanım (ikisinden biri):
  python3 upload_firebase.py --project cengelish                 # gcloud ADC ile
  python3 upload_firebase.py --key /yol/serviceAccount.json      # hizmet hesabı anahtarıyla

ADC için bir kez: gcloud auth application-default login

Yüklenenler:
  packs/{packId}                 paket listesi (manifest; contentPath = packContents/{id}_v{n})
  packContents/{packId}_v{n}     `data`: gzip'li PackPayload JSON (Bytes)
  dailies/{yyyy-MM-dd}           günlük bulmacalar (bulmaca + kelimeler)
  words/{wordId}                 soru havuzu (yönetim için; uygulama okumaz)
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / "out" / "firestore"
STARTER = HERE.parent.parent / "Cengelish/AppCore/ContentKit/Sources/Resources/starter.json"


def batched(items: list[tuple[str, str, dict]], size: int = 400):
    """Firestore toplu yazma sınırına (500) uygun parçalar."""
    for start in range(0, len(items), size):
        yield items[start : start + size]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--key", help="Firebase hizmet hesabı JSON dosyası (yoksa ADC kullanılır)")
    ap.add_argument("--project", default="cengelish", help="Firebase proje kimliği")
    ap.add_argument("--dry-run", action="store_true", help="Sadece ne yükleneceğini yaz")
    args = ap.parse_args()

    packs = json.loads((OUT / "packs.json").read_text(encoding="utf-8"))
    dailies = json.loads((OUT / "dailies.json").read_text(encoding="utf-8"))
    words = json.loads(STARTER.read_text(encoding="utf-8"))["words"]
    contents = sorted((OUT / "packContents").glob("*.json.gz"))
    print(f"{len(packs)} paket, {len(contents)} paket içeriği, {len(dailies)} günlük, {len(words)} kelime")
    if args.dry_run:
        return

    import firebase_admin
    from firebase_admin import credentials, firestore

    cred = credentials.Certificate(args.key) if args.key else credentials.ApplicationDefault()
    firebase_admin.initialize_app(cred, {"projectId": args.project})
    db = firestore.client()

    writes: list[tuple[str, str, dict]] = []
    for path in contents:
        doc_id = path.name.removesuffix(".json.gz")
        writes.append(("packContents", doc_id, {"data": path.read_bytes()}))
    writes += [("packs", p["id"], p) for p in packs]
    writes += [("dailies", d["date"], d) for d in dailies]
    writes += [("words", w["id"], w) for w in words]

    for chunk in batched(writes):
        batch = db.batch()
        for collection, doc_id, data in chunk:
            batch.set(db.collection(collection).document(doc_id), data)
        batch.commit()
    print(f"Firestore: {len(writes)} belge yazıldı")


if __name__ == "__main__":
    main()
