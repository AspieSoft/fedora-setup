#!/bin/bash

cd $(dirname "$0")
dir="$PWD"


function waitForWifi() {
  wget -q --spider http://google.com
  if ! [ $? -eq 0 ]; then
    echo
    echo "Internet Connection Error: Waiting for wifi..."
    echo

    sleep 10

    wget -q --spider http://google.com

    while ! [ $? -eq 0 ]; do
      sleep 3
      wget -q --spider http://google.com
    done
  fi
}


echo "starting update for aspiesoft-fedora-setup"

gitVer="$(curl --silent 'https://api.github.com/repos/AspieSoft/fedora-setup/releases/latest' | grep '\"tag_name\":' | sed -E 's/.*\"([^\"]+)\".*/\1/')"

if [ "$gitVer" = "" ]; then
  echo "error: failed to connect to github!"
  exit
fi

ver="$(cat version.txt)"

if [ "$ver" = "$gitVer" ]; then
  echo "already up to date!"
  exit
fi

echo "updating $ver -> $gitVer"

waitForWifi; git clone https://github.com/AspieSoft/fedora-setup.git

cd fedora-setup

waitForWifi
for file in bin/scripts/*.sh; do
  gitSum=$(curl --silent "https://raw.githubusercontent.com/AspieSoft/fedora-setup/master/$file" | sha256sum | sed -E 's/([a-zA-Z0-9]+).*$/\1/')
  sum=$(sha256sum "$file" | sed -E 's/([a-zA-Z0-9]+).*$/\1/')
  if ! [ "$sum" = "$gitSum" ]; then
    echo "error: checksum failed!"
    exit
  fi
done

sudo nice -n 15 clamscan && sudo clamscan -r --bell --move="/VirusScan/quarantine" --exclude-dir="/VirusScan/quarantine" "$PWD/assets"

cd bin/updates
readarray -d '' fileList < <(printf '%s\0' *.sh | sort -zV)
cd ../../

for file in "${fileList[@]}"; do
  fileVer=(${file//./ })
  if ! [ "$ver" == "${fileVer[0]}.${fileVer[1]}.${fileVer[2]}" ]; then
    verN=(${ver//./ })
    if [ "${verN[0]}" -le "${fileVer[0]}" ] && [ "${verN[1]}" -le "${fileVer[1]}" ] && [ "${verN[2]}" -le "${fileVer[2]}" ]; then
      waitForWifi
      gitSum=$(curl --silent "https://raw.githubusercontent.com/AspieSoft/fedora-setup/master/bin/updates/$file" | sha256sum | sed -E 's/([a-zA-Z0-9]+).*$/\1/')
      sum=$(sha256sum "bin/updates/$file" | sed -E 's/([a-zA-Z0-9]+).*$/\1/')
      if [ "$sum" = "$gitSum" ]; then
        echo "updating $ver -> ${fileVer[0]}.${fileVer[1]}.${fileVer[2]}"
        sudo bash "./bin/updates/$file"
        ver="${fileVer[0]}.${fileVer[1]}.${fileVer[2]}"
      else
        echo "checksum failed for update ${fileVer[0]}.${fileVer[1]}.${fileVer[2]}"
      fi
    fi
  fi
done

cd "$dir"
rm -rf fedora-setup
echo "$ver" | sudo tee "version.txt"

if [ "$ver" = "$gitVer" ]; then
  echo "now up to date!"
else
  echo "failed to finish update!"
fi

echo "updated to $ver"
echo "latest $getVer"
