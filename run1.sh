# Compilation du firmware
cargo build -Zbuild-std=core,compiler_builtins --target ./x86_64-unknown-uefi.json

# Convertir le binaire ELF en EFI exécutable
# objcopy -I elf64-x86-64 -O binary target/x86_64-unknown-uefi/debug/bootx64 target/x86_64-unknown-uefi/debug/BOOTX64.EFI
objcopy -I elf64-x86-64 -O pei-x86-64 target/x86_64-unknown-uefi/debug/bootx64 target/x86_64-unknown-uefi/debug/BOOTX64.EFI
# cp target/x86_64-unknown-uefi/debug/bootx64.efi target/x86_64-unknown-uefi/debug/BOOTX64.EFI

# Creer une image du dique FAT avec l'EFI
mkdir -p esp/EFI/BOOT
cp target/x86_64-unknown-uefi/debug/BOOTX64.EFI esp/EFI/BOOT/
qemu-img create -f raw fat.img 64M
mformat -i fat.img -h 32 -t 32 -n 64 -c 1
mcopy -i fat.img -s esp/* ::

# Copier les variables OVMF
cp /usr/share/OVMF/OVMF_VARS_4M.fd .

# Lancer QEMU avec OVMF et l'image FAT
echo "Lancement de QEMU"
qemu-system-x86_64 \
    -bios /usr/share/OVMF/OVMF_CODE_4M.fd \
    -drive if=pflash,format=raw,file=./OVMF_VARS_4M.fd \
    -drive format=raw,file=fat.img \
    -nographic


# qemu-system-x86_64     -bios /usr/share/OVMF/OVMF_CODE_4M.fd     -drive file=fat.img,format=raw     -drive if=pflash,format=raw,file=OVMF_VARS_4M.fd
