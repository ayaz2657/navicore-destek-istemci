#!/usr/bin/env bash
# NaviCore Destek -- Linux'a ozel markalama. brand.sh'TAN SONRA, derleme ONCESI repo kokunden calisir.
# Neden: Linux kodu APP_NAME'in kucuk harflisini servis adi (systemctl), surec arama
# (ps | grep '<ad> --server'), masaustu dosyasi ve URI oneki olarak kullanir
# (src/platform/linux.rs, src/common.rs get_uri_prefix). Calistirilabilir dosyanin adi da
# ayni olmali; yoksa servis/surec yonetimi bozulur. Paket tarafi: navicore/linux_repack.sh.
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source navicore/brand.env
BIN=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')

rep() {  # rep <dosya> <python-regex> <yerine> -- tam N eslesme bekler (varsayilan 1)
  python3 - "$1" "$2" "$3" "${4:-1}" <<'PY'
import re, sys
path, pat, new, want = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
s = open(path, encoding="utf-8").read()
n = len(re.findall(pat, s, flags=re.M))
if n != want:
    sys.exit(f"brand-linux.sh: {path}: beklenen {want} eslesme, bulunan {n}: {pat}")
s = re.sub(pat, lambda m: new, s, flags=re.M)
open(path, "w", encoding="utf-8", newline="").write(s)
print(f"ok  {path}")
PY
}

# Calistirilabilir dosya adi = APP_NAME kucuk harf (librustdesk.so adi DEGISMEZ: main.cc dlopen eder)
rep flutter/linux/CMakeLists.txt '^set\(BINARY_NAME "rustdesk"\)$' "set(BINARY_NAME \"$BIN\")"

MA=flutter/linux/my_application.cc
# Pencere simgesi sistem temasindan bu adla aranir (paket: /usr/share/icons/hicolor/*/apps/<ad>.png)
rep "$MA" 'gtk_icon_theme_load_icon\(theme, "rustdesk",' "gtk_icon_theme_load_icon(theme, \"$BIN\","
# Pencere basligi
rep "$MA" 'gtk_header_bar_set_title\(header_bar, "rustdesk"\);' "gtk_header_bar_set_title(header_bar, \"$PRODUCT_NAME\");"
rep "$MA" 'gtk_window_set_title\(window, "rustdesk"\);' "gtk_window_set_title(window, \"$PRODUCT_NAME\");"

echo "NaviCore Linux markalamasi uygulandi: ikili=$BIN"
