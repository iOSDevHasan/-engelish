"""Çengelish App Store önizleme videosu (886x1920, 30 fps, ~26 sn).

Kullanım:
  python3 tools/store_video/build.py <kayıt.mp4> <seslendirme.mp3> <çıktı.mp4> [müzik.mp3]

<kayıt.mp4>: `xcrun simctl io <id> recordVideo` ile iPhone 17 Pro Max'ta (1320x2868) alınmış,
Debug derleme + `-screenshotDemo` ile açılış → ana sayfa → bulmaca (HOT el yazısı) → cevap
anahtarı → ana sayfa → defter → Keşfet akışı. SEGMENTS'teki kaynak süreleri bu kayda göredir;
yeni kayıtta güncellenmelidir.
Başlık kartları Playwright (Chromium) ile çizilir; `STORE_CHROMIUM` ile tarayıcı yolu verilebilir.
"""
import os
import pathlib
import subprocess
import sys
import tempfile

from playwright.sync_api import sync_playwright

W, H, FPS = 886, 1920, 30
# Çerçeveli sahnede uygulama görüntüsünün yeri (1320x2868 oranı korunur).
WIN_W, WIN_X, WIN_Y = 664, 111, 400
WIN_H = round(WIN_W * 2868 / 1320 / 2) * 2
RADIUS = 64

# (kaynak başlangıç, kaynak süre, hedef süre, düzen, başlık, gradyan renkleri)
SEGMENTS = [
    (7.85, 3.05, 4.1, "full", None, None),
    (17.0, 2.9, 2.9, "frame", "Türkçe ipucu<br><em>İngilizce cevap</em>", ("#FF8A5C", "#FF6F7D")),
    (34.2, 2.6, 1.9, "frame", "Kalemle <em>yaz</em> ✍️", ("#FF6F7D", "#EC5FA8")),
    (47.0, 1.8, 1.8, "frame", "Cevap anahtarıyla<br><em>kontrol et</em>", ("#FF6F7D", "#EC5FA8")),
    (56.0, 2.3, 2.3, "frame", "Her gün <em>yeni</em><br>bir bulmaca", ("#EC5FA8", "#C062C8")),
    (66.6, 3.8, 3.8, "frame", "Bilemediğin kelime<br><em>deftere</em> düşer", ("#C062C8", "#8E5FE0")),
    (73.2, 5.1, 5.1, "frame", "YDS · YÖKDİL · LGS<br><em>IELTS · TOEFL</em>", ("#8E5FE0", "#6C5CE7")),
    (10.6, 0, 4.6, "end", "Bulmaca çöz,<br><em>İngilizceni geliştir!</em>", None),
]

CSS = """
@font-face { font-family: R; src: url(file:///System/Library/Fonts/SFNSRounded.ttf); }
* { margin: 0; box-sizing: border-box; }
html, body { width: %dpx; height: %dpx; overflow: hidden; background: transparent; }
body { font-family: R, -apple-system, sans-serif; color: #fff; position: relative; }
h1 { position: absolute; left: 40px; right: 40px; text-align: center; font-weight: 900;
  font-size: 66px; line-height: 1.08; letter-spacing: -1px; text-shadow: 0 4px 24px rgba(60,20,120,.3); }
h1 em { font-style: normal; color: #FFE27A; }
""" % (W, H)


def frame_bg(title, colors):
    a, b = colors
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>{CSS}
body {{ background: linear-gradient(160deg, {a}, {b}); }}
body::before {{ content: ""; position: absolute; inset: 0;
  background: radial-gradient(700px 500px at 50% 0%, rgba(255,255,255,.25), transparent 70%); }}
.grid {{ position: absolute; inset: 0; opacity: .10;
  background-image: linear-gradient(#fff 2px, transparent 2px), linear-gradient(90deg, #fff 2px, transparent 2px);
  background-size: 89px 89px; -webkit-mask-image: linear-gradient(#000, transparent 30%); }}
.shadow {{ position: absolute; left: {WIN_X}px; top: {WIN_Y}px; width: {WIN_W}px; height: {WIN_H}px;
  border-radius: {RADIUS}px; background: #F3EEE4;
  box-shadow: 0 30px 80px rgba(40,10,100,.40), 0 8px 24px rgba(40,10,100,.25); }}
h1 {{ top: 120px; }}
</style></head><body><div class="grid"></div><h1>{title}</h1><div class="shadow"></div></body></html>"""


def end_overlay(title):
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>{CSS}
h1 {{ top: 1470px; font-size: 70px; }}
</style></head><body><h1>{title}</h1></body></html>"""


def mask():
    return f"""<!doctype html><html><head><style>
html, body {{ margin: 0; width: {WIN_W}px; height: {WIN_H}px; background: #000; }}
div {{ width: 100%; height: 100%; border-radius: {RADIUS}px; background: #fff; }}
</style></head><body><div></div></body></html>"""


def render(pages, tmp):
    """HTML sayfalarını PNG'ye çevirir: {ad: (html, genişlik, yükseklik, saydam)}."""
    with sync_playwright() as pw:
        browser = pw.chromium.launch(
            executable_path=os.environ.get("STORE_CHROMIUM") or None,
            args=["--allow-file-access-from-files"])
        for name, (html, w, h, transparent) in pages.items():
            tab = browser.new_page(viewport={"width": w, "height": h}, device_scale_factor=1)
            path = pathlib.Path(tmp, f"{name}.html")
            path.write_text(html, encoding="utf-8")
            tab.goto(path.as_uri())
            tab.evaluate("document.fonts.ready")
            tab.screenshot(path=str(pathlib.Path(tmp, f"{name}.png")), omit_background=transparent)
            tab.close()
        browser.close()


def ff(*args):
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *args], check=True)


ENC = ["-c:v", "libx264", "-preset", "slow", "-crf", "16", "-pix_fmt", "yuv420p",
       "-r", str(FPS), "-an"]


def segment(i, seg, rec, tmp):
    start, src, dur, layout, _, _ = seg
    out = str(pathlib.Path(tmp, f"seg{i}.mp4"))
    speed = f"setpts=PTS*{dur / src:.5f}," if src and abs(src - dur) > 0.01 else ""
    full = f"scale={W}:-2,crop={W}:{H},fps={FPS}"
    if layout == "full":
        ff("-ss", str(start), "-t", str(src), "-i", rec,
           "-vf", f"{speed}{full}", "-t", str(dur), *ENC, out)
    elif layout == "frame":
        ff("-loop", "1", "-i", f"{tmp}/bg{i}.png",
           "-ss", str(start), "-t", str(src), "-i", rec,
           "-loop", "1", "-i", f"{tmp}/mask.png",
           "-filter_complex",
           f"[1:v]{speed}fps={FPS},scale={WIN_W}:{WIN_H}[app];"
           f"[2:v]format=gray[m];[app][m]alphamerge[win];"
           f"[0:v][win]overlay={WIN_X}:{WIN_Y}:shortest=1,format=yuv420p",
           "-t", str(dur), *ENC, out)
    else:  # Kapanış: açılış ekranının son karesi, yavaş yakınlaşma ve başlık.
        still = f"{tmp}/still.png"
        ff("-ss", str(start), "-i", rec, "-frames:v", "1", "-vf", f"scale={W}:-2,crop={W}:{H}", still)
        frames = int(dur * FPS)
        ff("-loop", "1", "-i", still, "-loop", "1", "-i", f"{tmp}/end.png",
           "-filter_complex",
           f"[0:v]scale={W * 2}:{H * 2},zoompan=z='1+0.06*on/{frames}':d={frames}:"
           f"x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s={W}x{H}:fps={FPS}[bg];"
           f"[bg][1:v]overlay=0:0,fade=out:st={dur - 0.5}:d=0.5,format=yuv420p",
           "-t", str(dur), *ENC, out)
    return out


def main():
    rec, voice, out = sys.argv[1], sys.argv[2], sys.argv[3]
    music = sys.argv[4] if len(sys.argv) > 4 else None
    with tempfile.TemporaryDirectory() as tmp:
        pages = {"mask": (mask(), WIN_W, WIN_H, False)}
        for i, (_, _, _, layout, title, colors) in enumerate(SEGMENTS):
            if layout == "frame":
                pages[f"bg{i}"] = (frame_bg(title, colors), W, H, False)
            elif layout == "end":
                pages["end"] = (end_overlay(title), W, H, True)
        render(pages, tmp)
        # Simülatör kaydı değişken kare hızlı: ekran durağanken kare yazmaz. Kesmeden önce sabit
        # 30 fps'e çevrilir; yoksa sahne başında ilk kare gelene kadar pencere siyah kalır.
        cfr = f"{tmp}/cfr.mp4"
        ff("-i", rec, "-vf", f"fps={FPS}", "-c:v", "libx264", "-preset", "fast", "-crf", "10",
           "-pix_fmt", "yuv420p", "-an", cfr)
        parts = [segment(i, s, cfr, tmp) for i, s in enumerate(SEGMENTS)]
        listing = pathlib.Path(tmp, "list.txt")
        listing.write_text("".join(f"file '{p}'\n" for p in parts))
        video = f"{tmp}/video.mp4"
        ff("-f", "concat", "-safe", "0", "-i", str(listing), "-c", "copy", video)
        total = sum(s[2] for s in SEGMENTS)
        if music:
            audio = (f"[1:a]loudnorm=I=-16:TP=-1.5:LRA=7,aresample=48000,apad[vo];"
                     f"[2:a]loudnorm=I=-28:TP=-8,aresample=48000,afade=in:0:d=0.4,"
                     f"afade=out:st={total - 1.6}:d=1.6[mu];"
                     f"[vo][mu]amix=inputs=2:duration=first:normalize=0,"
                     f"atrim=0:{total},alimiter=limit=0.95[a]")
            inputs = ["-i", voice, "-i", music]
        else:
            audio = (f"[1:a]loudnorm=I=-16:TP=-1.5:LRA=7,aresample=48000,apad,atrim=0:{total},"
                     f"afade=out:st={total - 0.8}:d=0.8[a]")
            inputs = ["-i", voice]
        ff("-i", video, *inputs, "-filter_complex", audio, "-map", "0:v", "-map", "[a]",
           "-c:v", "copy", "-c:a", "aac", "-b:a", "256k", "-ar", "48000", "-ac", "2",
           "-movflags", "+faststart", "-t", f"{total:.2f}", out)
    print(out)


if __name__ == "__main__":
    main()
