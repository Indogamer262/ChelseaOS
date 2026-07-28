#!/bin/bash

# ChelseaOS Version: 1.2
# Install Bloatware
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y gimp krita obs-studio snapd unzip
flatpak install --system -y --noninteractive flathub org.telegram.desktop

# Create Chelsea Directory Structure (Menggunakan -p agar aman jika sudah ada)
mkdir -p ~/Pictures/Wallpaper/
mkdir -p ~/Pictures/Icons/
mkdir -p ~/Documents/Obsidian/
mkdir -p ~/.themes/
mkdir -p ~/.fonts/
mkdir -p ~/.local/share/icons/  # Memastikan folder ikon lokal terbuat

# Download Resources
wget -P ~/Pictures/Icons/ https://content.christianah.my.id/chelsea-os/chel.png
wget -P ~/Pictures/Wallpaper/ https://content.christianah.my.id/chelsea-os/defaultWallpaper.jpg
wget -P ~/.fonts/ https://content.christianah.my.id/chelsea-os/NotoColorEmoji-Regular.ttf
wget -P ~/Desktop/ https://content.christianah.my.id/chelsea-os/chel.jpeg
wget -P ~/.local/share/icons/ https://content.christianah.my.id/chelsea-os/Papirus-chelsea_matcha-dark.zip
wget -P ~/.themes/ https://content.christianah.my.id/chelsea-os/chelsea-matcha-dark.zip

# Unzip & delete zip (Ditambahkan parameter -d agar ekstrak ke tempat yang benar)
unzip ~/.local/share/icons/Papirus-chelsea_matcha-dark.zip -d ~/.local/share/icons/
rm ~/.local/share/icons/Papirus-chelsea_matcha-dark.zip

unzip ~/.themes/chelsea-matcha-dark.zip -d ~/.themes/
rm ~/.themes/chelsea-matcha-dark.zip

# Configure system
xfconf-query -c xsettings -p /Net/ThemeName -s chelsea-matcha-dark
xfconf-query -c xsettings -p /Net/IconThemeName -s Papirus-chelsea_matcha-dark

# 2. Cari ID plugin Whiskermenu secara dinamis di xfce4-panel
WHISKER_PROP=$(xfconf-query -c xfce4-panel -l -v | grep 'whiskermenu' | awk '{print $1}')

if [ ! -z "$WHISKER_PROP" ]; then
    # Memastikan tipe data string (-t string) dan set nilainya (-s) ke path gambar Chelsea
    xfconf-query -c xfce4-panel -p "${WHISKER_PROP}/button-icon" -t string -s "$HOME/Pictures/Icons/chel.png"
    
    # Mengubah title agar bersih (kosong) atau disesuaikan jika diinginkan
    xfconf-query -c xfce4-panel -p "${WHISKER_PROP}/button-title" -t string -s "ChelseaOS"
    
    echo "Icon configuration success"
else
    echo "Peringatan: Plugin Whisker Menu tidak ditemukan di panel XFCE."
fi

# 3. Konfigurasi Notification Timeout (Disappear after 15 seconds)
xfconf-query -c xfce4-notifyd -p /expire-timeout -n -t int -s 15
echo "Notification timeout configuration success"