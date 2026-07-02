#!/bin/bash
set -e

if [ "$USER" != "root" ]; then
    echo "Run as root. (sudo)"
    exit
fi


CURRENT_DIR=$(pwd)
INSTALL_WORKDIR="/tmp/resolve-studio-install-script"
RESOLVE_DIR="/opt/resolve"


mkdir "$INSTALL_WORKDIR"


echo Installing deps...
dnf install -y libxcrypt-compat apr apr-util mesa-libGLU gcc


# DaVinci Resolve Studio 20.3.2
echo Downloading Resolve Studio...
resolve_download_link=$(curl -X POST "https://www.blackmagicdesign.com/api/register/us/download/19d7b1f6daf94f7f8203c68f17237b30" \
    --http2 \
    -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:152.0) Gecko/20100101 Firefox/152.0" \
    -H "Content-Type: application/json;charset=utf-8" \
    -d '{
            "country": "us",
            "downloadOnly": true,
            "origin": "www.blackmagicdesign.com",
            "platform": "Linux",
            "policy": true,
            "product": {
                "name": "DaVinci Resolve Studio"
        }
    }')

wget -O "$INSTALL_WORKDIR"/resolve.zip -c --tries=0 --read-timeout=20 "$resolve_download_link"


echo Extracting Resolve Studio...
unzip "$INSTALL_WORKDIR"/resolve.zip -d "$INSTALL_WORKDIR"
cd "$INSTALL_WORKDIR"
./*.run --appimage-extract
cd "$CURRENT_DIR"


echo Installing Resolve Studio...
yes | SKIP_PACKAGE_CHECK=1 "$INSTALL_WORKDIR"/squashfs-root/AppRun -i


echo Fixing libs...
mkdir "$RESOLVE_DIR"/libs/disabled-libraries
mv "$RESOLVE_DIR"/libs/libgio* "$RESOLVE_DIR"/libs/libglib* "$RESOLVE_DIR"/libs/libgmodule* "$RESOLVE_DIR"/libs/disabled-libraries


echo Applying Resolve Studio crack...
perl -pi -e 's/\x03\x00\x89\x45\xFC\x83\x7D\xFC\x00\x74\x11\x48\x8B\x45\xC8\x8B/\x03\x00\x89\x45\xFC\x83\x7D\xFC\x00\xEB\x11\x48\x8B\x45\xC8\x8B/' "$RESOLVE_DIR"/bin/resolve
perl -pi -e 's/\x74\x11\x48\x8B\x45\xC8\x8B\x55\xFC\x89\x50\x58\xB8\x00\x00\x00/\xEB\x11\x48\x8B\x45\xC8\x8B\x55\xFC\x89\x50\x58\xB8\x00\x00\x00/' "$RESOLVE_DIR"/bin/resolve
perl -pi -e 's/\x41\xb6\x01\x84\xc0\x0f\x84\xb0\x00\x00\x00\x48\x85\xdb\x74\x08\x45\x31\xf6\xe9\xa3\x00\x00\x00/\x41\xb6\x00\x84\xc0\x0f\x84\xb0\x00\x00\x00\x48\x85\xdb\x74\x08\x45\x31\xf6\xe9\xa3\x00\x00\x00/' "$RESOLVE_DIR"/bin/resolve
echo -e "LICENSE blackmagic davinciresolvestudio 999999 permanent uncounted\n  hostid=ANY issuer=CGP customer=CGP issued=28-dec-2023\n  akey=0000-0000-0000-0000 _ck=00 sig=\"00\"" | tee "$RESOLVE_DIR/".license/blackmagic.lic


echo Applying AAC fix...
su "$LOCAL_USER" -c "curl -fsSL https://davinci-resolve-linux-aac-fix.netlify.app/install.sh | bash"

rm -rf "$INSTALL_WORKDIR"
