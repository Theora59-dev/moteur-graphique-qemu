#!/bin/bash
set -e

# Chemins
TARGET_DIR=target/x86_64-unknown-uefi/debug
ESP_DIR=esp

# Compilation du firmware Rust
cargo build -Zbuild-std=core,compiler_builtins --target ./x86_64-unknown-uefi.json

# Créer l'image FAT
rm -f fat.img
qemu-img create -f raw fat.img 64M

# Préparer le répertoire EFI
mkdir -p $ESP_DIR/EFI/BOOT
cp $TARGET_DIR/BOOTX64.EFI $ESP_DIR/EFI/BOOT/

# Copier le contenu dans l'image FAT
mformat -i fat.img -h 32 -t 32 -n 64 -c 1
mcopy -i fat.img -s $ESP_DIR/* ::

# Copier les variables OVMF
cp /usr/share/OVMF/OVMF_VARS_4M.fd .

# Lancer QEMU avec OVMF et sortie série
echo "Lancement de QEMU..."
qemu-system-x86_64 \
    -bios /usr/share/OVMF/OVMF_CODE_4M.fd \
    -drive if=pflash,format=raw,file=./OVMF_VARS_4M.fd \
    -drive format=raw,file=fat.img \
    -serial stdio
