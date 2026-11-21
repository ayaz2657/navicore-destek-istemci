# NaviCore Destek istemcisi

RustDesk 1.5.3'ün NaviCore markalı derlemesidir (AGPL-3.0; kaynak bu repodadır).

| Değişiklik | Dosya |
|---|---|
| Uygulama adı `NaviCore-Destek`, dosya bilgileri | `navicore/brand.env` → `brand.sh` (derlemede uygulanır) |
| Gömülü sunucu `destek.navicore.com.tr` + açık anahtar | aynı |
| Android APK (arm64 + armv7), paket kimliği `tr.com.navicore.destek` (`brand.env` ANDROID_APP_ID — yayından sonra değiştirilmez) | `.github/workflows/navicore-android.yml` (aynı üretici) + `navicore/brand-android.sh` (ad, derin bağlantı şeması `navicore-destek://`, bildirim metinleri, simgeler) + `navicore/android/gen_icons.py` (simgeleri `res/scalable.svg`'den üretir) |
| NaviCore simgeleri | `navicore/res`, `navicore/win`, `navicore/flutter_assets` |
| Yalnız Windows x64 derleme | `.github/workflows/navicore-windows.yml` (`navicore/gen_workflow.py` üretir) |
| Linux x86_64 `.deb` (paket `navicore-destek`) | `.github/workflows/navicore-linux.yml` (aynı üretici) + `navicore/brand-linux.sh` (ikili adı, pencere başlığı/simgesi) + `navicore/linux_repack.sh` (paket/servis/masaüstü adları) |

Derleme: `navicore-*` dalına push veya Actions → "NaviCore Destek Windows" → Run workflow.
Çıktı: Actions artifact `NaviCore-Destek-<sürüm>-Kurulum` (`.exe` + `SHA256SUMS.txt`).

Linux: aynı push "NaviCore Destek Linux"u da çalıştırır → release `navicore-linux-<sürüm>-r<n>`,
`NaviCore-Destek-<sürüm>-x86_64.deb` + `SHA256SUMS.txt`. Linux kodu `APP_NAME`'in küçük harflisini
servis adı, süreç arama (`ps | grep '<ad> --server'`), masaüstü dosyası ve URI şeması (`navicore-destek://`)
olarak kullandığı için ikili/servis/paket adı `navicore-destek`tir; resmi `rustdesk` paketiyle çakışmaz.
Kurulum: `apt install ./NaviCore-Destek-*.deb` → servis `navicore-destek`, komut `navicore-destek --config/--password/--get-id`.

Upstream güncellemesi: yeni etiketten `navicore-<sürüm>` dalı aç → `navicore/` klasörünü taşı →
`python3 navicore/gen_workflow.py` → push. Upstream dosyalarında kalıcı değişiklik yoktur.

Sunucu tarafı: https://github.com/ayaz2657/RustDesk (özel).

Android imzası: GitHub'da gizli anahtar YOKTUR; CI çıktısı (`navicore-android-<sürüm>-r<n>`, `*-test.apk`) geçici
debug anahtarıyla imzalıdır → yalnız test, üzerine güncelleme kurulmaz. Müşteriye giden APK kalıcı NaviCore
anahtarıyla yeniden imzalanır (anahtar kaybolursa uygulama bir daha güncellenemez → yedeklenir).
