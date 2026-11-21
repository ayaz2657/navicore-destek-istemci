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

# API (adres defteri/giris/heartbeat): ozel sunucu yokken varsayilan admin.rustdesk.com -> bizim API (src/common.rs get_api_server_)
rep src/common.rs '^    "https://admin\.rustdesk\.com"\.to_owned\(\)$' "    \"$API_SERVER\".to_owned()"

rep Cargo.toml '^ProductName = "RustDesk"$'                  "ProductName = \"$PRODUCT_NAME\""
rep Cargo.toml '^FileDescription = "RustDesk Remote Desktop"$' "FileDescription = \"$FILE_DESCRIPTION\""
rep Cargo.toml '^LegalCopyright = ".*"$'                     "LegalCopyright = \"$LEGAL_COPYRIGHT\""

# Yerlesik ayarlar (normalde Pro'nun imzali ayar dosyasi doldurur): musteri sunucu/anahtar/API'yi degistiremez,
# Kimlik degistirilemez, RustDesk yardim kartlari gizli. Guvenlik ayarlari ACIK (musteri kalici parola belirler).
rep "$CFG" '^(\s*)pub static ref BUILTIN_SETTINGS: RwLock<HashMap<String, String>> = Default::default\(\);' \
    '    pub static ref BUILTIN_SETTINGS: RwLock<HashMap<String, String>> = RwLock::new(HashMap::from([("hide-server-settings".to_owned(), "Y".to_owned()), ("hide-proxy-settings".to_owned(), "Y".to_owned()), ("hide-websocket-settings".to_owned(), "Y".to_owned()), ("disable-change-id".to_owned(), "Y".to_owned()), ("hide-help-cards".to_owned(), "Y".to_owned())]));'

# Windows mesaj kutusu basligi
rep src/platform/windows.rs '^    let caption = "RustDesk Output"$' "    let caption = \"$PRODUCT_NAME\""

# Kurulum kabugu (self-extracting packer) dosya bilgileri
PK=libs/portable/Cargo.toml
rep "$PK" '^ProductName = "RustDesk"$'                  "ProductName = \"$PRODUCT_NAME\""
rep "$PK" '^FileDescription = "RustDesk Remote Desktop"$' "FileDescription = \"$FILE_DESCRIPTION\""
rep "$PK" '^LegalCopyright = ".*"$'                     "LegalCopyright = \"$LEGAL_COPYRIGHT\""

# Ana sayfadaki "Powered by RustDesk" baglantisi gizlenir (lisans/atif "Hakkinda" sayfasinda kalir)
rep flutter/lib/common.dart '^  if \(bind\.mainGetBuildinOption\(key: "hide-powered-by-me"\) == .Y.\) \{$' \
    "  if (true) { // NaviCore: powered-by gizli (atif Hakkinda sayfasinda)"

RC=flutter/windows/runner/Runner.rc
rep "$RC" 'VALUE "CompanyName", "[^"]*"'     "VALUE \"CompanyName\", \"$COMPANY_NAME\""
rep "$RC" 'VALUE "FileDescription", "[^"]*"' "VALUE \"FileDescription\", \"$FILE_DESCRIPTION\""
rep "$RC" 'VALUE "LegalCopyright", "[^"]*"'  "VALUE \"LegalCopyright\", \"$LEGAL_COPYRIGHT\""
rep "$RC" 'VALUE "ProductName", "[^"]*"'     "VALUE \"ProductName\", \"$PRODUCT_NAME\""

# Simgeler (NaviCore pusula madalyonu)
for f in navicore/res/*; do [[ -f "res/$(basename "$f")" ]] || { echo "brand.sh: res/$(basename "$f") upstream'de yok"; exit 1; }; cp "$f" res/; done
cp navicore/win/app_icon.ico flutter/windows/runner/resources/app_icon.ico
cp navicore/flutter_assets/icon.svg flutter/assets/icon.svg
# Ana sayfa logosu (common.dart _Logo: assets/logo.png, koyu temada logo_dark.png; en fazla 300x60)
cp navicore/flutter_assets/logo.png navicore/flutter_assets/logo_dark.png flutter/assets/
echo "NaviCore markalamasi uygulandi: APP_NAME=$APP_NAME, sunucu=$RENDEZVOUS_SERVER"
