#!/usr/bin/env bash
# NaviCore Destek -- upstream build.py'nin urettigi rustdesk .deb paketini navicore-destek paketine cevirir.
# Kullanim: bash navicore/linux_repack.sh <girdi.deb> <cikti.deb>   (root ya da sudo; dosya sahipligi korunur)
# Yapilan: /usr/share/rustdesk -> /usr/share/<ad>, servis/masaustu/simge adlari, DEBIAN betikleri ve control,
# md5sums yeniden. Beklenen bir yol yoksa (upstream degistiyse) HATA ile durur.
# lib/librustdesk.so adi DEGISMEZ (calistirilabilir dosya onu bu adla yukler).
set -euo pipefail
[[ $# -eq 2 ]] || { echo "kullanim: $0 <girdi.deb> <cikti.deb>" >&2; exit 1; }
IN=$(readlink -f "$1"); OUT=$(readlink -m "$2")
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
source "$HERE/brand.env"
BIN=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')
die() { echo "linux_repack.sh: HATA: $*" >&2; exit 1; }

W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
R="$W/p"
dpkg-deb -R "$IN" "$R"
grep -qx 'Package: rustdesk' "$R/DEBIAN/control" || die "girdi paketi 'rustdesk' degil"

mvx() { [[ -e "$R/$1" ]] || die "beklenen yol yok: $1"; mv "$R/$1" "$R/$2"; }
mvx usr/share/rustdesk "usr/share/$BIN"
[[ -x "$R/usr/share/$BIN/$BIN" ]] || die "usr/share/$BIN/$BIN yok (brand-linux.sh BINARY_NAME uygulanmamis)"
[[ -e "$R/usr/share/$BIN/rustdesk" ]] && die "eski 'rustdesk' ikilisi pakette duruyor"
[[ -f "$R/usr/share/$BIN/lib/librustdesk.so" ]] || die "lib/librustdesk.so yok"
mvx "usr/share/$BIN/files/systemd/rustdesk.service" "usr/share/$BIN/files/systemd/$BIN.service"
mvx usr/share/icons/hicolor/256x256/apps/rustdesk.png "usr/share/icons/hicolor/256x256/apps/$BIN.png"
mvx usr/share/icons/hicolor/scalable/apps/rustdesk.svg "usr/share/icons/hicolor/scalable/apps/$BIN.svg"
mvx usr/share/applications/rustdesk.desktop "usr/share/applications/$BIN.desktop"
mvx usr/share/applications/rustdesk-link.desktop "usr/share/applications/$BIN-link.desktop"

# Metin dosyalari: kucuk harfli 'rustdesk' -> ikili adi (yollar, servis, pkill/grep kaliplari, URI semasi)
SVC="$R/usr/share/$BIN/files/systemd/$BIN.service"
TXT=("$SVC" "$R/usr/share/applications/$BIN.desktop" "$R/usr/share/applications/$BIN-link.desktop")
for f in preinst postinst prerm postrm; do [[ -f "$R/DEBIAN/$f" ]] && TXT+=("$R/DEBIAN/$f"); done
sed -i "s/rustdesk/$BIN/g" "${TXT[@]}"
sed -i "s/^Description=RustDesk\$/Description=$PRODUCT_NAME/" "$SVC"
sed -i "s/^Name=RustDesk\$/Name=$PRODUCT_NAME/" "$R/usr/share/applications/$BIN.desktop" "$R/usr/share/applications/$BIN-link.desktop"
sed -i "s/^GenericName=Remote Desktop\$/GenericName=$FILE_DESCRIPTION/" "$R/usr/share/applications/$BIN.desktop"
grep -l 'rustdesk' "${TXT[@]}" && die "donusmeyen 'rustdesk' kaldi (yukaridaki dosyalar)"
grep -q "^ExecStart=/usr/bin/$BIN --service\$" "$SVC" || die "servis ExecStart beklenen bicimde degil"

# control: paket adi + bakimci; bagimliliklar ve surum upstream'den aynen
C="$R/DEBIAN/control"
sed -i -e "s/^Package: rustdesk\$/Package: $BIN/" \
       -e "s/^Maintainer: .*/Maintainer: $COMPANY_NAME <destek@navicore.com.tr>/" \
       -e "s|^Homepage: .*|Homepage: $API_SERVER|" \
       -e "s/^Description: .*/Description: $FILE_DESCRIPTION (RustDesk tabanli, AGPL-3.0)/" "$C"
grep -qx "Package: $BIN" "$C" || die "control Package degismedi"

# md5sums yeniden (yollar degisti)
( cd "$R" && find . -path ./DEBIAN -prune -o -type f -printf '%P\0' | sort -z | xargs -0 md5sum ) > "$R/DEBIAN/md5sums"
dpkg-deb --root-owner-group -Zxz -b "$R" "$OUT" >/dev/null
dpkg-deb -f "$OUT" Package Version Architecture
echo "uretildi: $OUT"
