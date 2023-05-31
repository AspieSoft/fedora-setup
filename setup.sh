#!/bin/bash

cd $(dirname "$0")

if ! [ "$1" = "-y" ]; then
  echo
  echo "Notice: This script will completely transform your desktop and modify your settings!"
  echo "Creating a backup first is recommended."
  echo "Your gnome session will restart (and log you out) when the install is complete."
  echo
  read -n1 -p "Would you like to continue with the install (Y/n)? " input ; echo >&2

  if ! [ "$input" = "y" -o "$input" = "Y" -o "$input" = "" -o "$input" = " " ] ; then
    echo "install canceled!"
    exit
  fi

  echo "Starting Install..."
  echo
fi

function cleanup() {
  # reset login timeout
  sudo sed -r -i 's/^Defaults([\t ]+)(.*)env_reset(.*), (timestamp_timeout=1801,?\s*)+$/Defaults\1\2env_reset\3/m' /etc/sudoers &>/dev/null

  # enable sleep
  sudo systemctl --runtime unmask sleep.target suspend.target hibernate.target hybrid-sleep.target &>/dev/null

  # enable auto updates
  gsettings set org.gnome.software download-updates true
}
trap cleanup EXIT


# To log into sudo with password prompt
sudo echo


# extend login timeout
sudo sed -r -i 's/^Defaults([\t ]+)(.*)env_reset(.*)$/Defaults\1\2env_reset\3, timestamp_timeout=1801/m' /etc/sudoers &>/dev/null

# disable sleep
sudo systemctl --runtime mask sleep.target suspend.target hibernate.target hybrid-sleep.target &>/dev/null

# disable auto updates
gsettings set org.gnome.software download-updates false


gsettings set org.gnome.desktop.interface clock-format 12h
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

echo "#Added for Speed" | sudo tee -a /etc/dnf/dnf.conf
echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf
echo "max_parallel_downloads=5" | sudo tee -a /etc/dnf/dnf.conf
echo "defaultyes=True" | sudo tee -a /etc/dnf/dnf.conf
echo "keepcache=True" | sudo tee -a /etc/dnf/dnf.conf

sudo dnf -y update

sudo dnf -y install ufw
sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo systemctl enable ufw
sudo systemctl start ufw
sudo ufw enable
sudo ufw delete allow SSH
sudo ufw delete allow to 244.0.0.251 app mDNS
sudo ufw delete allow to ff02::fb app mDNS

sudo dnf -y makecache

sudo dnf -y install python python3 python-pip
sudo dnf -y install gcc-c++ make gcc
sudo dnf -y install java-1.8.0-openjdk.x86_64
sudo dnf -y install java-11-openjdk.x86_64
sudo dnf -y install java-latest-openjdk.x86_64

sudo dnf -y install nodejs
sudo npm -g i npm
npm config set prefix ~/.npm
sudo touch "$HOME/.zshrc"
sudo touch "$HOME/.profile"
echo 'export N_PREFIX="~/.npm"' | sudo tee -a "$HOME/.zshrc"
echo 'export N_PREFIX="~/.npm"' | sudo tee -a "$HOME/.profile"
sudo mkdir $(whoami) "~/.npm"
sudo chown -R $(whoami) "~/.npm"

sudo npm -g i yarn
sudo dnf -y install git
sudo dnf -y install golang

sudo cp -n /etc/default/grub /etc/default/grub-backup
sudo sed -r -i 's/^GRUB_TIMEOUT_STYLE=(.*)$/GRUB_TIMEOUT_STYLE=menu/m' /etc/default/grub
sudo sed -r -i 's/^GRUB_TIMEOUT=(.*)$/GRUB_TIMEOUT=0/m' /etc/default/grub
sudo update-grub

sudo dnf -y copr enable elxreno/preload
sudo dnf -y install preload
sudo systemctl start preload
sudo systemctl enable preload

sudo dnf -y install tlp-rdw
sudo systemctl start tlp
sudo systemctl enable tlp
sudo tlp start

sudo dnf -y install thermald
sudo systemctl start thermald
sudo systemctl enable thermald

sudo systemctl disable NetworkManager-wait-online.service
sudo systemctl disable systemd-networkd.service
sudo systemctl disable accounts-daemon.service
sudo systemctl disable debug-shell.service
sudo systemctl disable nfs-client.target
sudo systemctl disable remote-fs.target

sudo dnf -y --noautoremove remove dmraid device-mapper-multipath

sudo dnf -y install btrfs-progs lvm2 xfsprogs udftools
sudo dnf -y install hplip hplip-gui

sudo touch "$HOME/.hidden"
echo "core" | sudo tee -a "$HOME/.hidden"
echo "snap" | sudo tee -a "$HOME/.hidden"
echo "Steam" | sudo tee -a "$HOME/.hidden"

sudo dnf -y install clamav clamd clamav-update
sudo systemctl stop clamav-freshclam
sudo freshclam
sudo systemctl enable clamav-freshclam --now
sudo dnf -y install clamtk

sudo dnf -y install cronie

sudo freshclam
sudo mkdir -p /VirusScan/quarantine
sudo chmod 664 /VirusScan/quarantine

if grep -R "^ScanOnAccess " "/etc/clamd.d/scan.conf"; then
  sudo sed -r -i 's/^ScanOnAccess (.*)$/ScanOnAccess yes/m' "/etc/clamd.d/scan.conf"
else
  echo 'ScanOnAccess yes' | sudo tee -a "/etc/clamd.d/scan.conf"
fi

if grep -R "^OnAccessMountPath " "/etc/clamd.d/scan.conf"; then
  sudo sed -r -i 's#^OnAccessMountPath (.*)$#OnAccessMountPath /#m' "/etc/clamd.d/scan.conf"
else
  echo 'OnAccessMountPath /' | sudo tee -a "/etc/clamd.d/scan.conf"
fi

if grep -R "^OnAccessPrevention " "/etc/clamd.d/scan.conf"; then
  sudo sed -r -i 's/^OnAccessPrevention (.*)$/OnAccessPrevention no/m' "/etc/clamd.d/scan.conf"
else
  echo 'OnAccessPrevention no' | sudo tee -a "/etc/clamd.d/scan.conf"
fi

if grep -R "^OnAccessExtraScanning " "/etc/clamd.d/scan.conf"; then
  sudo sed -r -i 's/^OnAccessExtraScanning (.*)$/OnAccessExtraScanning yes/m' "/etc/clamd.d/scan.conf"
else
  echo 'OnAccessExtraScanning yes' | sudo tee -a "/etc/clamd.d/scan.conf"
fi

if grep -R "^OnAccessExcludeUID " "/etc/clamd.d/scan.conf"; then
  sudo sed -r -i 's/^OnAccessExcludeUID (.*)$/OnAccessExcludeUID 0/m' "/etc/clamd.d/scan.conf"
else
  echo 'OnAccessExcludeUID 0' | sudo tee -a "/etc/clamd.d/scan.conf"
fi

if grep -R "^User " "/etc/clamd.d/scan.conf"; then
  sudo sed -r -i 's/^User (.*)$/User root/m' "/etc/clamd.d/scan.conf"
else
  echo 'User root' | sudo tee -a "/etc/clamd.d/scan.conf"
fi

sudo dnf -y install bleachbit

sudo dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf -y install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo fedora-third-party enable
sudo fedora-third-party refresh
sudo dnf -y groupupdate core

sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

sudo dnf install -y --skip-broken @multimedia
sudo dnf -y groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin --skip-broken
sudo dnf -y groupupdate sound-and-video

sudo dnf -y install fedora-workstation-repositories
sudo dnf -y config-manager --set-enabled google-chrome

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
if ! test -f "/etc/yum.repos.d/vscode.repo" ; then
  echo '[code]' | sudo tee -a "/etc/yum.repos.d/vscode.repo"
  echo 'name=Visual Studio Code' | sudo tee -a "/etc/yum.repos.d/vscode.repo"
  echo 'baseurl=https://packages.microsoft.com/yumrepos/vscode' | sudo tee -a "/etc/yum.repos.d/vscode.repo"
  echo 'enabled=1' | sudo tee -a "/etc/yum.repos.d/vscode.repo"
  echo 'gpgcheck=1' | sudo tee -a "/etc/yum.repos.d/vscode.repo"
  echo 'gpgkey=https://packages.microsoft.com/keys/microsoft.asc' | sudo tee -a "/etc/yum.repos.d/vscode.repo"
fi

sudo rpm --import https://packagecloud.io/AtomEditor/atom/gpgkey
if ! test -f "/etc/yum.repos.d/atom.repo" ; then
  echo '[Atom]' | sudo tee -a "/etc/yum.repos.d/atom.repo"
  echo 'name=atom' | sudo tee -a "/etc/yum.repos.d/atom.repo"
  echo 'baseurl=https://packagecloud.io/AtomEditor/atom/el/7/$basearch' | sudo tee -a "/etc/yum.repos.d/atom.repo"
  echo 'enabled=1' | sudo tee -a "/etc/yum.repos.d/atom.repo"
  echo 'gpgcheck=0' | sudo tee -a "/etc/yum.repos.d/atom.repo"
  echo 'repo_gpgcheck=1' | sudo tee -a "/etc/yum.repos.d/atom.repo"
  echo 'gpgkey=https://packagecloud.io/AtomEditor/atom/gpgkey' | sudo tee -a "/etc/yum.repos.d/atom.repo"
fi

sudo dnf -y check-update

sudo dnf -y update
sudo dnf -y install neofetch
sudo flatpak install -y flathub com.github.tchx84.Flatseal

sudo dnf -y install nemo
xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
sudo sed -r -i "s/^OnlyShowIn=/#OnlyShowIn=/m" "/usr/share/applications/nemo.desktop"
sudo dnf -y install nemo-fileroller
sudo sed -r -i 's#^inode/directory=(.*)$#inode/directory=nemo.desktop#m' "/usr/share/applications/gnome-mimeapps.list"
echo 'OnlyShowIn=X-Cinnamon;Budgie;' | sudo tee -a "/usr/share/applications/nautilus-autorun-software.desktop"
sudo sed -r -i 's/^\[Desktop Action new-window\]/OnlyShowIn=X-Cinnamon;Budgie;\n\n[Desktop Action new-window]/m' "/usr/share/applications/org.gnome.Nautilus.desktop"

sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/38/winehq.repo
sudo dnf -y install winehq-stable
sudo dnf -y install alsa-plugins-pulseaudio.i686 glibc-devel.i686 glibc-devel libgcc.i686 libX11-devel.i686 freetype-devel.i686 libXcursor-devel.i686 libXi-devel.i686 libXext-devel.i686 libXxf86vm-devel.i686 libXrandr-devel.i686 libXinerama-devel.i686 mesa-libGLU-devel.i686 mesa-libOSMesa-devel.i686 libXrender-devel.i686 libpcap-devel.i686 ncurses-devel.i686 libzip-devel.i686 lcms2-devel.i686 zlib-devel.i686 libv4l-devel.i686 libgphoto2-devel.i686  cups-devel.i686 libxml2-devel.i686 openldap-devel.i686 libxslt-devel.i686 gnutls-devel.i686 libpng-devel.i686 flac-libs.i686 json-c.i686 libICE.i686 libSM.i686 libXtst.i686 libasyncns.i686 libedit.i686 liberation-narrow-fonts.noarch libieee1284.i686 libogg.i686 libsndfile.i686 libuuid.i686 libva.i686 libvorbis.i686 libwayland-client.i686 libwayland-server.i686 llvm-libs.i686 mesa-dri-drivers.i686 mesa-filesystem.i686 mesa-libEGL.i686 mesa-libgbm.i686 nss-mdns.i686 ocl-icd.i686 pulseaudio-libs.i686  sane-backends-libs.i686 tcp_wrappers-libs.i686 unixODBC.i686 samba-common-tools.x86_64 samba-libs.x86_64 samba-winbind.x86_64 samba-winbind-clients.x86_64 samba-winbind-modules.x86_64 mesa-libGL-devel.i686 fontconfig-devel.i686 libXcomposite-devel.i686 libtiff-devel.i686 openal-soft-devel.i686 mesa-libOpenCL-devel.i686 opencl-utils-devel.i686 alsa-lib-devel.i686 gsm-devel.i686 libjpeg-turbo-devel.i686 pulseaudio-libs-devel.i686 pulseaudio-libs-devel gtk3-devel.i686 libattr-devel.i686 libva-devel.i686 libexif-devel.i686 libexif.i686 glib2-devel.i686 mpg123-devel.i686 mpg123-devel.x86_64 libcom_err-devel.i686 libcom_err-devel.x86_64 libFAudio-devel.i686 libFAudio-devel.x86_64
sudo dnf -y groupinstall "C Development Tools and Libraries"
sudo dnf -y groupinstall "Development Tools"

sudo dnf -y install dconf-editor gnome-tweaks

sudo flatpak install -y flathub org.gnome.Extensions
sudo flatpak install -y flathub com.mattjakeman.ExtensionManager

sudo dnf -y install gparted
sudo dnf -y install chromium
sudo dnf -y install vlc

sudo dnf -y --skip-broken install ffmpeg
sudo flatpak install -y flathub com.obsproject.Studio

sudo flatpak install -y flathub org.shotcut.Shotcut

sudo dnf -y install atom
sudo dnf -y install code
sudo flatpak install -y flathub org.eclipse.Java

sudo flatpak install -y flathub org.blender.Blender
sudo flatpak install -y flathub org.gimp.GIMP
sudo dnf -y install pinta

sudo dnf -y module disable nodejs
sudo dnf -y install steam
sudo dnf -y module install -y --allowerasing nodejs:16/development

sudo flatpak install -y flathub com.github.unrud.VideoDownloader

sudo dnf -y update
sudo dnf clean all

# setup theme
git clone https://github.com/vinceliuice/Fluent-gtk-theme.git
sudo bash Fluent-gtk-theme/install.sh --theme all --dest /usr/share/themes --size standard --icon zorin --tweaks round noborder
rm -rf Fluent-gtk-theme

git clone https://github.com/ZorinOS/zorin-icon-themes.git
for filename in zorin-icon-themes/Zorin*; do
  sudo cp zorin-icon-themes/LICENSE "$filename"
done
sudo cp -r zorin-icon-themes/Zorin* /usr/share/icons
rm -rf zorin-icon-themes

sudo cp -r ./assets/sounds/* /usr/share/sounds
sudo mkdir /usr/share/backgrounds/AspieSoft
sudo cp -r ./assets/backgrounds/* /usr/share/backgrounds/AspieSoft

gsettings set org.gnome.desktop.interface gtk-theme "Fluent-round-Dark"
gsettings set org.gnome.desktop.interface icon-theme "ZorinBlue-Dark"
gsettings set org.gnome.desktop.sound theme-name "zorin-pokemon"
gsettings set org.gnome.desktop.background picture-uri "file:///usr/share/backgrounds/AspieSoft/lightblue.jpg"
gsettings set org.gnome.desktop.background picture-uri-dark "file:///usr/share/backgrounds/AspieSoft/black.jpg"

sudo pip3 install --upgrade git+https://github.com/essembeh/gnome-extensions-cli

gext disable background-logo@fedorahosted.org

gext -F install arcmenu@arcmenu.com
gext -F install dash-to-panel@jderose9.github.com
gext -F install vertical-workspaces@G-dH.github.com
gext -F install user-theme@gnome-shell-extensions.gcampax.github.com
gext -F install gnome-ui-tune@itstime.tech
gext -F install gtk4-ding@smedius.gitlab.com
gext -F install drive-menu@gnome-shell-extensions.gcampax.github.com
gext -F install date-menu-formatter@marcinjakubowski.github.com
gext -F install batterytime@typeof.pw
gext -F install ControlBlurEffectOnLockScreen@pratap.fastmail.fm
gext -F install screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com
gext -F install gestureimprovements@gestures
gext -F install just-perfection-desktop@just-perfection

gext -F install printers@linux-man.org
gext -F install clipboard-indicator@tudmotu.com

gext -F install burn-my-windows@schneegans.github.com
gext -F install compiz-alike-magic-lamp-effect@hermes83.github.com

gext -F install Vitals@CoreCoding.com
gext disable Vitals@CoreCoding.com

gext -F install allowlockedremotedesktop@kamens.us
gext disable allowlockedremotedesktop@kamens.us

# fix keyboard shortcuts
dconf reset /org/gnome/desktop/wm/keybindings/switch-to-workspace-up
dconf reset /org/gnome/desktop/wm/keybindings/switch-to-workspace-down
dconf reset /org/gnome/desktop/wm/keybindings/switch-to-workspace-left
dconf reset /org/gnome/desktop/wm/keybindings/switch-to-workspace-right

dconf reset /org/gnome/desktop/wm/keybindings/move-to-workspace-up
dconf reset /org/gnome/desktop/wm/keybindings/move-to-workspace-down
dconf reset /org/gnome/desktop/wm/keybindings/move-to-workspace-left
dconf reset /org/gnome/desktop/wm/keybindings/move-to-workspace-right

dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-up "['<Super>Up']"
dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-down "['<Super>Down']"
dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-left "['<Super>Left']"
dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-right "['<Super>Right']"

dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-up "['<Shift><Super>Up']"
dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-down "['<Shift><Super>Down']"
dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-left "['<Shift><Super>Left']"
dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-right "['<Shift><Super>Right']"

# setup arcmenu
gsettings --schemadir ~/.local/share/gnome-shell/extensions/arcmenu@arcmenu.com/schemas/ set org.gnome.shell.extensions.arcmenu arcmenu-extra-categories-links "[(0, false), (1, true), (2, false), (3, false), (4, true)]"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/arcmenu@arcmenu.com/schemas/ set org.gnome.shell.extensions.arcmenu custom-menu-button-icon-size "24.0"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/arcmenu@arcmenu.com/schemas/ set org.gnome.shell.extensions.arcmenu directory-shortcuts-list "[['Computer', 'drive-harddisk-symbolic', 'ArcMenu_Computer'], ['Home', 'user-home-symbolic', 'ArcMenu_Home'], ['Documents', '. GThemedIcon folder-documents-symbolic folder-symbolic folder-documents folder', 'ArcMenu_Documents'], ['Downloads', '. GThemedIcon folder-download-symbolic folder-symbolic folder-download folder', 'ArcMenu_Downloads'], ['Pictures', '. GThemedIcon folder-pictures-symbolic folder-symbolic folder-pictures folder', 'ArcMenu_Pictures'], ['Videos', '. GThemedIcon folder-videos-symbolic folder-symbolic folder-videos folder', 'ArcMenu_Videos'], ['Music', '. GThemedIcon folder-music-symbolic folder-symbolic folder-music folder', 'ArcMenu_Music']]"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/arcmenu@arcmenu.com/schemas/ set org.gnome.shell.extensions.arcmenu extra-categories "[(0, false), (1, false), (3, true), (4, false), (2, true)]"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/arcmenu@arcmenu.com/schemas/ set org.gnome.shell.extensions.arcmenu hide-overview-on-startup "true"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/arcmenu@arcmenu.com/schemas/ set org.gnome.shell.extensions.arcmenu enable-menu-hotkey "false"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/arcmenu@arcmenu.com/schemas/ set org.gnome.shell.extensions.arcmenu application-shortcuts-list "[['Software', 'org.gnome.Software', 'ArcMenu_Software'], ['Settings', 'org.gnome.Settings', 'org.gnome.Settings.desktop'], ['Terminal', 'org.gnome.Terminal', 'org.gnome.Terminal.desktop'], ['System Monitor', 'org.gnome.SystemMonitor', 'gnome-system-monitor.desktop']]"

# setup dash to panel
gsettings --schemadir ~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas/ set org.gnome.shell.extensions.dash-to-panel hide-overview-on-startup "true"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas/ set org.gnome.shell.extensions.dash-to-panel intellihide "true"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas/ set org.gnome.shell.extensions.dash-to-panel intellihide-behaviour "ALL_WINDOWS"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas/ set org.gnome.shell.extensions.dash-to-panel intellihide-hide-from-windows "true"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas/ set org.gnome.shell.extensions.dash-to-panel intellihide-only-secondary "true"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas/ set org.gnome.shell.extensions.dash-to-panel isolate-monitors "true"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas/ set org.gnome.shell.extensions.dash-to-panel isolate-workspaces "true"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas/ set org.gnome.shell.extensions.dash-to-panel panel-element-positions '{"0":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}],"1":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}]}'
gsettings --schemadir ~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas/ set org.gnome.shell.extensions.dash-to-panel dot-style-unfocused "DOTS"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas/ set org.gnome.shell.extensions.dash-to-panel panel-sizes "{"0":42,"1":42}"

# setup vertical workspaces
gsettings --schemadir ~/.local/share/gnome-shell/extensions/vertical-workspaces@G-dH.github.com/schemas/ set org.gnome.shell.extensions.vertical-workspaces fix-ubuntu-dock "true"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/vertical-workspaces@G-dH.github.com/schemas/ set org.gnome.shell.extensions.vertical-workspaces hot-corner-action "0"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/vertical-workspaces@G-dH.github.com/schemas/ set org.gnome.shell.extensions.vertical-workspaces overview-bg-blur-sigma "10"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/vertical-workspaces@G-dH.github.com/schemas/ set org.gnome.shell.extensions.vertical-workspaces search-fuzzy "true"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/vertical-workspaces@G-dH.github.com/schemas/ set org.gnome.shell.extensions.vertical-workspaces blur-transitions "true"

# setup desktop icons
gsettings --schemadir ~/.local/share/gnome-shell/extensions/gtk4-ding@smedius.gitlab.com/schemas/ set org.gnome.shell.extensions.gtk4-ding show-drop-place "false"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/gtk4-ding@smedius.gitlab.com/schemas/ set org.gnome.shell.extensions.gtk4-ding show-home "false"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/gtk4-ding@smedius.gitlab.com/schemas/ set org.gnome.shell.extensions.gtk4-ding show-second-monitor "true"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/gtk4-ding@smedius.gitlab.com/schemas/ set org.gnome.shell.extensions.gtk4-ding use-nemo "true"

# setup burn my windows
sudo cp ./assets/extensions/burn-my-windows.conf "$HOME/.config/burn-my-windows/profiles"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/burn-my-windows@schneegans.github.com/schemas/ set org.gnome.shell.extensions.burn-my-windows active-profile "$HOME/.config/burn-my-windows/profiles/burn-my-windows.conf"

# setup date formatter
gsettings --schemadir ~/.local/share/gnome-shell/extensions/date-menu-formatter@marcinjakubowski.github.com/schemas/ set org.gnome.shell.extensions.date-menu-formatter apply-all-panels "true"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/date-menu-formatter@marcinjakubowski.github.com/schemas/ set org.gnome.shell.extensions.date-menu-formatter pattern "EEE, MMM d  h:mm aaa"

# setup printers
gsettings --schemadir ~/.local/share/gnome-shell/extensions/printers@linux-man.org/schemas/ set org.gnome.shell.extensions.printers show-icon "When printing"

# setup just perfection
gsettings --schemadir ~/.local/share/gnome-shell/extensions/just-perfection-desktop@just-perfection/schemas/ set org.gnome.shell.extensions.just-perfection hot-corner "false"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/just-perfection-desktop@just-perfection/schemas/ set org.gnome.shell.extensions.just-perfection startup-status "0"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/just-perfection-desktop@just-perfection/schemas/ set org.gnome.shell.extensions.just-perfection workspace-wrap-around "true"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/just-perfection-desktop@just-perfection/schemas/ set org.gnome.shell.extensions.just-perfection window-demands-attention-focus "false"

# setup user theme
gsettings --schemadir ~/.local/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com/schemas/ set org.gnome.shell.extensions.user-theme name "Fluent-round-Dark"

# other config options
gsettings set org.gnome.TextEditor restore-session "false"



# clean up and restart gnome
cd $(dirname "$0")
if [[ "$PWD" =~ fedora-setup/?$ ]]; then
  rm -rf "$PWD"
fi

# reset login timeout
sudo sed -r -i 's/^Defaults([\t ]+)(.*)env_reset(.*), (timestamp_timeout=1801,?\s*)+$/Defaults\1\2env_reset\3/m' /etc/sudoers &>/dev/null

# enable sleep
sudo systemctl --runtime unmask sleep.target suspend.target hibernate.target hybrid-sleep.target &>/dev/null

# enable auto updates
gsettings set org.gnome.software download-updates true

echo "Install Finished!"

# note: this will logout the user
killall -3 gnome-shell
