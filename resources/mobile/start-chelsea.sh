#!/data/data/com.termux/files/usr/bin/bash

# ==========================================
#  ChelseaOS Mobile Launcher
# ==========================================

clear
echo "========================================"
echo "    ChelseaOS Mobile Launcher Menu      "
echo "========================================"
echo "Silakan pilih mode tampilan:"
echo "1) Termux-X11 (Tampilan Lokal di HP)"
echo "2) TigerVNC Server (Remote via IP Lokal)"
echo "3) XRDP Server (Remote via IP Lokal + Audio)"
echo "4) Keluar"
echo "----------------------------------------"
read -p "Masukkan pilihan [1-4]: " choice

case $choice in
    1)
        echo ""
        echo "[+] Memulai Mode Termux-X11..."
        
        # Kill open X11 processes
        kill -9 $(pgrep -f "termux.x11") 2>/dev/null

        # Enable PulseAudio over Network
        pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1

        # Prepare termux-x11 session
        export XDG_RUNTIME_DIR=${TMPDIR}
        termux-x11 :0 -extension MIT-SHM >/dev/null &

        # Wait a bit until termux-x11 gets started.
        sleep 3

        # Launch Termux X11 main activity
        am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
        sleep 1

        # Login in PRoot Environment
        proot-distro login debian --shared-tmp -- /bin/bash -c 'export PULSE_SERVER=127.0.0.1 && export XDG_RUNTIME_DIR=${TMPDIR} && su - chelsea -c "env DISPLAY=:0 startxfce4"'
        ;;

    2)
        echo ""
        echo "[+] Memulai Mode TigerVNC Server..."
        
        # Ambil IP Lokal HP di Termux
        LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}')
        if [ -z "$LOCAL_IP" ]; then
            LOCAL_IP=$(ip -4 addr show wlan0 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
        fi

        # Enable PulseAudio over Network
        pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1

        # Pastikan file ~/.vnc/xstartup secara otomatis memuat XFCE dan PulseAudio
        proot-distro login debian --shared-tmp -- /bin/bash -c 'su - chelsea -c "mkdir -p ~/.vnc && echo -e \"#!/bin/sh\nexport PULSE_SERVER=127.0.0.1\nexec startxfce4\" > ~/.vnc/xstartup && chmod +x ~/.vnc/xstartup"'

        echo "----------------------------------------------------"
        echo "VNC Server berjalan di port 5901 (Display :1)"
        echo "Akses dari PC/VNC Viewer menggunakan alamat IP:"
        echo " -> ${LOCAL_IP:-IP-HP-Kamu}:5901 atau ${LOCAL_IP:-IP-HP-Kamu}:1"
        echo "----------------------------------------------------"
        echo "[!] JANGAN TUTUP TERMINAL INI SELAMA PAKAI VNC!"
        echo "[!] Tekan Ctrl+C di terminal ini untuk mematikan VNC Server."
        echo "----------------------------------------------------"

        # Login ke PRoot, jalankan VNC, lalu tahan proses dengan 'tail -f' agar PRoot tidak exit!
        proot-distro login debian --shared-tmp -- /bin/bash -c 'export PULSE_SERVER=127.0.0.1 && su - chelsea -c "vncserver -kill :1 2>/dev/null; rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1; vncserver :1 -geometry 1280x720 -depth 24 -localhost no && tail -f ~/.vnc/*.log"'
        ;;

    3)
        echo ""
        echo "[+] Memulai Mode XRDP Server (di Termux + Audio Support)..."
        
        # Ambil IP Lokal HP di Termux
        LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}')
        if [ -z "$LOCAL_IP" ]; then
            LOCAL_IP=$(ip -4 addr show wlan0 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
        fi

        # Enable PulseAudio and multicast-rtp over Network di Termux
        pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --load="module-rtp-send source=OpenSL_ES_sink.monitor port=4656 loop=true" --exit-idle-time=-1

        echo "----------------------------------------------------"
        echo "XRDP Server berjalan di port 3389"
        echo "Akses dari Client RDP (Windows Remote Desktop / Remmina):"
        echo " -> ${LOCAL_IP:-IP-HP-Kamu}:3389"
        echo "----------------------------------------------------"
        echo "[!] JANGAN TUTUP TERMINAL INI SELAMA PAKAI XRDP!"
        echo "[!] Tekan Ctrl+C di terminal ini untuk mematikan server."
        echo "----------------------------------------------------"

        # Jalankan xrdp-sesman dan xrdp langsung di Termux untuk membuka kontainer proot-distro, lalu pantau log
        proot-distro login debian --shared-tmp -- /bin/bash -c '
			export PULSE_SERVER=127.0.0.1
			rm -f /var/run/xrdp/xrdp-sesman.pid /var/run/xrdp/xrdp.pid
			xrdp-sesman
			xrdp
			tail -f /var/log/xrdp.log
		'
        ;;
    4)
        echo "Batal menjalankan OS."
        exit 0
        ;;

    *)
        echo "Pilihan tidak valid!"
        exit 1
        ;;
esac

exit 0