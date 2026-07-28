#!/usr/bin/env bash

# =================================================================
#  ChelseaOS Mobile - Desktop Launcher Patcher
#  Fungsi: Meng-append flag --no-sandbox pada berkas .desktop
#  di /usr/share/applications/ untuk lingkungan PRoot/Container
# =================================================================

APP_DIRS=("/usr/share/applications" "$HOME/.local/share/applications")

# Warna Output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Daftar kata kunci aplikasi berbasis Chromium/Electron populer
KNOWN_ELECTRON_APPS=("chromium" "code" "obsidian" "antigravity" "brave" "edge" "chrome" "discord" "vscode" "element" "slack")

check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        SUDO="sudo"
    else
        SUDO=""
    fi
}

# Fungsi untuk memeriksa status patch pada file .desktop
is_patched() {
    local file="$1"
    grep -q "^Exec=.*--no-sandbox" "$file" 2>/dev/null
    return $?
}

# Fungsi Patch File
patch_file() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo -e "${RED}[!] Berkas tidak ditemukan: $file${NC}"
        return 1
    fi

    if is_patched "$file"; then
        echo -e "${YELLOW}[i] Sudah di-patch sebelumnya: $(basename "$file")${NC}"
        return 0
    fi

    # Menyisipkan --no-sandbox sebelum argumen % (seperti %U, %f) atau di akhir baris Exec
    if grep -q "^Exec=.*%" "$file"; then
        $SUDO sed -i '/^Exec=/ s/^Exec=\([^%]*\)\(.*\)/Exec=\1--no-sandbox \2/' "$file"
    else
        $SUDO sed -i '/^Exec=/ s/$/ --no-sandbox/' "$file"
    fi

    if is_patched "$file"; then
        echo -e "${GREEN}[✓] Berhasil di-patch: $(basename "$file")${NC}"
    else
        echo -e "${RED}[X] Gagal mengaplikasikan patch pada: $(basename "$file")${NC}"
    fi
}

# Fungsi Unpatch File
unpatch_file() {
    local file="$1"
    if [ ! -f "$file" ]; then
        return 1
    fi

    if is_patched "$file"; then
        $SUDO sed -i '/^Exec=/ s/ --no-sandbox//g' "$file"
        $SUDO sed -i '/^Exec=/ s/--no-sandbox//g' "$file"
        echo -e "${CYAN}[✓] Patch --no-sandbox dicopot dari: $(basename "$file")${NC}"
    else
        echo -e "${YELLOW}[i] Berkas belum di-patch: $(basename "$file")${NC}"
    fi
}

# Mode 1: Auto-Detect & Patch Aplikasi Populer
auto_patch_known_apps() {
    echo ""
    echo -e "${BLUE}[+] Memindai aplikasi Chromium/Electron yang terpasang...${NC}"
    local count=0

    for dir in "${APP_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            for app in "${KNOWN_ELECTRON_APPS[@]}"; do
                for file in "$dir"/*"$app"*.desktop; do
                    if [ -f "$file" ]; then
                        patch_file "$file"
                        count=$((count + 1))
                    fi
                done
            done
        fi
    done

    if [ $count -eq 0 ]; then
        echo -e "${YELLOW}[i] Tidak ditemukan launcher Chromium/Electron populer di folder standar.${NC}"
    fi
}

# Mode 2: Cari & Pilih Manual (Filter-based)
search_and_patch_menu() {
    echo ""
    read -p "Masukkan nama/kata kunci aplikasi (misal: chrom, code, obs): " keyword
    if [ -z "$keyword" ]; then
        echo -e "${RED}[!] Kata kunci tidak boleh kosong.${NC}"
        return
    fi

    # Kumpulkan daftar file yang cocok
    local matches=()
    for dir in "${APP_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            while IFS= read -r file; do
                [ -f "$file" ] && matches+=("$file")
            done < <(find "$dir" -maxdepth 1 -iname "*$keyword*.desktop" 2>/dev/null)
        fi
    done

    if [ ${#matches[@]} -eq 0 ]; then
        echo -e "${YELLOW}[i] Tidak ada aplikasi .desktop yang cocok dengan kata kunci '$keyword'.${NC}"
        return
    fi

    echo ""
    echo -e "${CYAN}--- Hasil Pencarian Aplikasi ---${NC}"
    local i=1
    for file in "${matches[@]}"; do
        local fname=$(basename "$file")
        # Ambil Name= dari file desktop jika ada
        local app_name=$(grep -m1 "^Name=" "$file" | cut -d= -f2)
        [ -z "$app_name" ] && app_name="$fname"

        if is_patched "$file"; then
            echo -e "$i) $app_name (${GREEN}PATCHED${NC}) -> $fname"
        else
            echo -e "$i) $app_name (${RED}UNPATCHED${NC}) -> $fname"
        fi
        i=$((i + 1))
    done

    echo "0) Batal"
    echo "----------------------------------------"
    read -p "Pilih nomor aplikasi yang ingin di-patch/unpatch [0-$((i - 1))]: " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#matches[@]}" ]; then
        local target_file="${matches[$((choice - 1))]}"
        if is_patched "$target_file"; then
            read -p "Aplikasi ini sudah di-patch. Copot patch? (y/n): " confirm
            [ "$confirm" = "y" ] || [ "$confirm" = "Y" ] && unpatch_file "$target_file"
        else
            patch_file "$target_file"
        fi
    fi
}

# Mode 3: Tampilkan Semua Aplikasi Ter-patch
list_patched_apps() {
    echo ""
    echo -e "${GREEN}--- Daftar Aplikasi Ter-patch (--no-sandbox) ---${NC}"
    local count=0
    for dir in "${APP_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            for file in "$dir"/*.desktop; do
                if [ -f "$file" ] && is_patched "$file"; then
                    local fname=$(basename "$file")
                    echo -e " -> ${GREEN}$fname${NC} ($dir)"
                    count=$((count + 1))
                fi
            done
        fi
    done

    if [ $count -eq 0 ]; then
        echo -e "${YELLOW}[i] Belum ada aplikasi yang di-patch.${NC}"
    fi
}

# Main Loop Interactive Shell
check_sudo

while true; do
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${CYAN}     CHELSEA MOBILE PATCHER TOOL        ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo "1) Auto-Patch Aplikasi Chromium/Electron (Quick Patch)"
    echo "2) Cari & Pilih Aplikasi Manual (Search Keyword)"
    echo "3) Lihat Semua Aplikasi yang Sudah Di-patch"
    echo "4) Keluar"
    echo "----------------------------------------"
    read -p "Pilih opsi [1-4]: " main_choice

    case $main_choice in
        1)
            auto_patch_known_apps
            ;;
        2)
            search_and_patch_menu
            ;;
        3)
            list_patched_apps
            ;;
        4)
            echo "Keluar dari Patcher."
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Pilihan tidak valid.${NC}"
            ;;
    esac
done