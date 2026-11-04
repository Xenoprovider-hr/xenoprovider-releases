#!/usr/bin/env bash
# Installs or updates XOffice on Linux Mint from the public Xenoprovider releases repository.
#
#   curl -fsSL https://raw.githubusercontent.com/Xenoprovider-hr/xenoprovider-releases/HEAD/xoffice/install-xoffice.sh | bash
#   ./install-xoffice.sh [version]      e.g. ./install-xoffice.sh 1.2.0 (default: latest release)
set -euo pipefail

REPO="Xenoprovider-hr/xenoprovider-releases"

if [ $# -gt 0 ]; then
    VERSION="${1#xoffice-}"
    VERSION="${VERSION#v}"
else
    # The repository holds releases of several applications; pick the newest XOffice one.
    VERSION="$(curl -fsSL "https://api.github.com/repos/$REPO/releases?per_page=100" | python3 -c '
import json, sys
for release in json.load(sys.stdin):
    tag = release["tag_name"]
    if tag.startswith("xoffice-v") and not release["draft"] and not release["prerelease"]:
        print(tag[len("xoffice-v"):])
        break
')"
    if [ -z "$VERSION" ]; then
        echo "No XOffice release found in $REPO." >&2
        exit 1
    fi
fi

INSTALLED="$(dpkg-query --show --showformat='${Version}' xoffice 2>/dev/null || true)"
if [ "$INSTALLED" = "$VERSION" ]; then
    echo "XOffice $VERSION is already installed."
    exit 0
fi

DOWNLOAD="$(mktemp -d)"
trap 'rm -rf "$DOWNLOAD"' EXIT
PACKAGE="xoffice_${VERSION}_amd64.deb"

curl -fL --progress-bar -o "$DOWNLOAD/$PACKAGE" \
    "https://github.com/$REPO/releases/download/xoffice-v$VERSION/$PACKAGE"
# apt drops privileges to the _apt user while reading local packages.
chmod 755 "$DOWNLOAD"
sudo apt install -y "$DOWNLOAD/$PACKAGE"

echo "XOffice ${INSTALLED:+$INSTALLED -> }$VERSION installed."
