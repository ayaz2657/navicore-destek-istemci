# NaviCore Destek istemcisi

RustDesk 1.5.3'ün NaviCore markalı derlemesidir (AGPL-3.0; kaynak bu repodadır).

| Değişiklik | Dosya |
|---|---|
| Uygulama adı `NaviCore-Destek`, dosya bilgileri | `navicore/brand.env` → `brand.sh` (derlemede uygulanır) |
| Gömülü sunucu `destek.navicore.com.tr` + açık anahtar | aynı |
| NaviCore simgeleri | `navicore/res`, `navicore/win`, `navicore/flutter_assets` |
| Yalnız Windows x64 derleme | `.github/workflows/navicore-windows.yml` (`navicore/gen_workflow.py` üretir) |

Derleme: `navicore-*` dalına push veya Actions → "NaviCore Destek Windows" → Run workflow.
Çıktı: Actions artifact `NaviCore-Destek-<sürüm>-Kurulum` (`.exe` + `SHA256SUMS.txt`).

Upstream güncellemesi: yeni etiketten `navicore-<sürüm>` dalı aç → `navicore/` klasörünü taşı →
`python3 navicore/gen_workflow.py` → push. Upstream dosyalarında kalıcı değişiklik yoktur.

Sunucu tarafı: https://github.com/ayaz2657/RustDesk (özel).
