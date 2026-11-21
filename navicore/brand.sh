#!/usr/bin/env bash
# NaviCore Destek markalamasi -- derleme ONCESI, repo kokunden calisir (CI: "NaviCore branding" adimi).
# Upstream dosyalarina kalici degisiklik commit'lenmez; fork upstream'den catismasiz guncellenir.
# Her degisiklik dogrulanir: kalip bulunamazsa (upstream degistiyse) derleme HATA ile durur.
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source navicore/brand.env

rep() {  # rep <dosya> <python-regex> <yerine> -- tam 1 eslesme bekler
  python3 - "$1" "$2" "$3" <<'PY'
import re, sys
path, pat, new = sys.argv[1:4]
s = open(path, encoding="utf-8").read()
n = len(re.findall(pat, s, flags=re.M))
if n != 1:
    sys.exit(f"brand.sh: {path}: beklenen 1 eslesme, bulunan {n}: {pat}")
s = re.sub(pat, lambda m: new, s, flags=re.M)
open(path, "w", encoding="utf-8", newline="").write(s)
print(f"ok  {path}")
PY
}

CFG=libs/hbb_common/src/config.rs
rep "$CFG" '^(\s*)pub static ref APP_NAME: RwLock<String> = RwLock::new\("RustDesk"\.to_owned\(\)\);' \
    "    pub static ref APP_NAME: RwLock<String> = RwLock::new(\"$APP_NAME\".to_owned());"
rep "$CFG" '^pub const RENDEZVOUS_SERVERS: &\[&str\] = &\[[^\]]*\];' \
    "pub const RENDEZVOUS_SERVERS: &[&str] = &[\"$RENDEZVOUS_SERVER\"];"
rep "$CFG" '^pub const RS_PUB_KEY: &str = "[^"]*";' \
    "pub const RS_PUB_KEY: &str = \"$RS_PUB_KEY\";"

rep Cargo.toml '^ProductName = "RustDesk"$'                  "ProductName = \"$PRODUCT_NAME\""
rep Cargo.toml '^FileDescription = "RustDesk Remote Desktop"$' "FileDescription = \"$FILE_DESCRIPTION\""
rep Cargo.toml '^LegalCopyright = ".*"$'                     "LegalCopyright = \"$LEGAL_COPYRIGHT\""

RC=flutter/windows/runner/Runner.rc
rep "$RC" 'VALUE "CompanyName", "[^"]*"'     "VALUE \"CompanyName\", \"$COMPANY_NAME\""
rep "$RC" 'VALUE "FileDescription", "[^"]*"' "VALUE \"FileDescription\", \"$FILE_DESCRIPTION\""
rep "$RC" 'VALUE "LegalCopyright", "[^"]*"'  "VALUE \"LegalCopyright\", \"$LEGAL_COPYRIGHT\""
rep "$RC" 'VALUE "ProductName", "[^"]*"'     "VALUE \"ProductName\", \"$PRODUCT_NAME\""

# Simgeler (NaviCore pusula madalyonu)
for f in navicore/res/*; do [[ -f "res/$(basename "$f")" ]] || { echo "brand.sh: res/$(basename "$f") upstream'de yok"; exit 1; }; cp "$f" res/; done
cp navicore/win/app_icon.ico flutter/windows/runner/resources/app_icon.ico
cp navicore/flutter_assets/icon.svg flutter/assets/icon.svg
echo "NaviCore markalamasi uygulandi: APP_NAME=$APP_NAME, sunucu=$RENDEZVOUS_SERVER"
