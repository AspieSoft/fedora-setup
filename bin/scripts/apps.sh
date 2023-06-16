#!/bin/bash

waitForWifi sudo dnf -y update

# install common essentials
echo " - installing common essentials..."
waitForWifi sudo dnf -y install neofetch
waitForWifi sudo flatpak install -y flathub com.github.tchx84.Flatseal
waitForWifi sudo dnf -y install dconf-editor gnome-tweaks
waitForWifi sudo flatpak install -y flathub org.gnome.Extensions
waitForWifi sudo flatpak install -y flathub com.mattjakeman.ExtensionManager
waitForWifi sudo dnf -y install gparted

# install nemo file manager (and hide nautilus)
echo " - installing nemo file manager..."
waitForWifi sudo dnf -y install nemo
xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
sudo sed -r -i "s/^OnlyShowIn=/#OnlyShowIn=/m" "/usr/share/applications/nemo.desktop"
waitForWifi sudo dnf -y install nemo-fileroller
sudo sed -r -i 's#^inode/directory=(.*)$#inode/directory=nemo.desktop#m' "/usr/share/applications/gnome-mimeapps.list"
echo 'OnlyShowIn=X-Cinnamon;Budgie;' | sudo tee -a "/usr/share/applications/nautilus-autorun-software.desktop"
sudo sed -r -i 's/^\[Desktop Action new-window\]/OnlyShowIn=X-Cinnamon;Budgie;\n\n[Desktop Action new-window]/m' "/usr/share/applications/org.gnome.Nautilus.desktop"

# install wine
echo " - installing wine..."
waitForWifi sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/38/winehq.repo
waitForWifi sudo dnf -y install winehq-stable
waitForWifi sudo dnf -y install alsa-plugins-pulseaudio.i686 glibc-devel.i686 glibc-devel libgcc.i686 libX11-devel.i686 freetype-devel.i686 libXcursor-devel.i686 libXi-devel.i686 libXext-devel.i686 libXxf86vm-devel.i686 libXrandr-devel.i686 libXinerama-devel.i686 mesa-libGLU-devel.i686 mesa-libOSMesa-devel.i686 libXrender-devel.i686 libpcap-devel.i686 ncurses-devel.i686 libzip-devel.i686 lcms2-devel.i686 zlib-devel.i686 libv4l-devel.i686 libgphoto2-devel.i686  cups-devel.i686 libxml2-devel.i686 openldap-devel.i686 libxslt-devel.i686 gnutls-devel.i686 libpng-devel.i686 flac-libs.i686 json-c.i686 libICE.i686 libSM.i686 libXtst.i686 libasyncns.i686 libedit.i686 liberation-narrow-fonts.noarch libieee1284.i686 libogg.i686 libsndfile.i686 libuuid.i686 libva.i686 libvorbis.i686 libwayland-client.i686 libwayland-server.i686 llvm-libs.i686 mesa-dri-drivers.i686 mesa-filesystem.i686 mesa-libEGL.i686 mesa-libgbm.i686 nss-mdns.i686 ocl-icd.i686 pulseaudio-libs.i686  sane-backends-libs.i686 tcp_wrappers-libs.i686 unixODBC.i686 samba-common-tools.x86_64 samba-libs.x86_64 samba-winbind.x86_64 samba-winbind-clients.x86_64 samba-winbind-modules.x86_64 mesa-libGL-devel.i686 fontconfig-devel.i686 libXcomposite-devel.i686 libtiff-devel.i686 openal-soft-devel.i686 mesa-libOpenCL-devel.i686 opencl-utils-devel.i686 alsa-lib-devel.i686 gsm-devel.i686 libjpeg-turbo-devel.i686 pulseaudio-libs-devel.i686 pulseaudio-libs-devel gtk3-devel.i686 libattr-devel.i686 libva-devel.i686 libexif-devel.i686 libexif.i686 glib2-devel.i686 mpg123-devel.i686 mpg123-devel.x86_64 libcom_err-devel.i686 libcom_err-devel.x86_64 libFAudio-devel.i686 libFAudio-devel.x86_64
waitForWifi sudo dnf -y groupinstall "C Development Tools and Libraries"
waitForWifi sudo dnf -y groupinstall "Development Tools"

# install common tools
echo " - installing common tools..."
waitForWifi sudo dnf -y install vlc
waitForWifi sudo flatpak install -y flathub org.blender.Blender
waitForWifi sudo flatpak install -y flathub org.gimp.GIMP
waitForWifi sudo dnf -y install pinta
waitForWifi sudo flatpak install -y flathub com.github.unrud.VideoDownloader

# install video processing software
echo " - installing video processing software..."
waitForWifi sudo dnf -y --skip-broken install ffmpeg
waitForWifi sudo flatpak install -y flathub com.obsproject.Studio
waitForWifi sudo flatpak install -y flathub org.shotcut.Shotcut

# install code editors
echo " - installing code editors..."
waitForWifi sudo dnf -y install atom
waitForWifi sudo dnf -y install code
waitForWifi sudo flatpak install -y flathub org.eclipse.Java

# install browsers
echo " - installing chromium..."
waitForWifi sudo dnf -y install chromium

# install steam
echo " - installing steam..."
sudo dnf -y module disable nodejs
waitForWifi sudo dnf -y install steam
waitForWifi sudo dnf -y module install -y --allowerasing nodejs:16/development
if ! grep -q "Steam" "$HOME/.hidden" ; then
  echo "Steam" | sudo tee -a "$HOME/.hidden"
fi
if ! grep -q "Steam" "/etc/skel/.hidden" ; then
  echo "Steam" | sudo tee -a "/etc/skel/.hidden"
fi
