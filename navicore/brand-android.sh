#!/usr/bin/env bash
# NaviCore Destek -- Android'e ozel markalama. brand.sh'TAN SONRA, derleme ONCESI repo kokunden calisir.
# - applicationId ayri (resmi RustDesk ile ayni telefona kurulabilsin); namespace/Kotlin paketi DEGISMEZ
#   (JNI sinif yollari com.carriez.flutter_hbb'ye bagli).
# - Uygulama adi, erisilebilirlik servisi adi, bildirim metinleri.
# - Derin baglanti semasi = APP_NAME kucuk harf (src/common.rs get_uri_prefix).
# - Simgeler: navicore/android/res (navicore/android/gen_icons.py uretir).
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source navicore/brand.env
BIN=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')
: "${ANDROID_APP_ID:?brand.env ANDROID_APP_ID tanimli degil}"

rep() {  # rep <dosya> <python-regex> <yerine> -- tam 1 eslesme bekler
  python3 - "$1" "$2" "$3" <<'PY'
import re, sys
path, pat, new = sys.argv[1:4]
s = open(path, encoding="utf-8").read()
n = len(re.findall(pat, s, flags=re.M))
if n != 1:
    sys.exit(f"brand-android.sh: {path}: beklenen 1 eslesme, bulunan {n}: {pat}")
s = re.sub(pat, lambda m: new, s, flags=re.M)
open(path, "w", encoding="utf-8", newline="").write(s)
print(f"ok  {path}")
PY
}

A=flutter/android/app
rep "$A/build.gradle" '^(\s*)applicationId "com\.carriez\.flutter_hbb"$' "        applicationId \"$ANDROID_APP_ID\""

M=$A/src/main/AndroidManifest.xml
rep "$M" 'android:label="RustDesk"$'       "android:label=\"$PRODUCT_NAME\""
rep "$M" 'android:label="RustDesk Input"$' "android:label=\"$PRODUCT_NAME Giris\""
rep "$M" '<data android:scheme="rustdesk" />' "<data android:scheme=\"$BIN\" />"

S=$A/src/main/res/values/strings.xml
rep "$S" '<string name="app_name">RustDesk</string>' "<string name=\"app_name\">$PRODUCT_NAME</string>"
rep "$S" 'when RustDesk screen sharing is established' "when $PRODUCT_NAME screen sharing is established"
rep "$S" 'Keeps the RustDesk remote desktop host' "Keeps the $PRODUCT_NAME remote desktop host"

K=$A/src/main/kotlin/com/carriez/flutter_hbb
rep "$K/MainService.kt" '^const val DEFAULT_NOTIFY_TITLE = "RustDesk"$' "const val DEFAULT_NOTIFY_TITLE = \"$PRODUCT_NAME\""
rep "$K/MainService.kt" 'val channelName = "RustDesk Service"' "val channelName = \"$PRODUCT_NAME\""
rep "$K/MainService.kt" 'description = "RustDesk Service Channel"' "description = \"$PRODUCT_NAME\""
rep "$K/BootReceiver.kt" '"RustDesk is Open"' "\"$PRODUCT_NAME acik\""

# Simgeler (her dosyanin upstream'de karsiligi olmali)
for f in navicore/android/res/mipmap-*/*.png; do
  d="$A/src/main/res/${f#navicore/android/res/}"
  [[ -f "$d" ]] || { echo "brand-android.sh: $d upstream'de yok"; exit 1; }
  cp "$f" "$d"
done
echo "NaviCore Android markalamasi uygulandi: applicationId=$ANDROID_APP_ID, sema=$BIN"
