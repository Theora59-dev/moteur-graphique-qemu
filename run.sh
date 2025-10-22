cargo build -Z build-std=core,compiler_builtins --target x86_64-unknown-uefi

echo "Lancement de l'UEFI ..."
uefi-runner target/x86_64-unknown-uefi/debug/bootx64.efi


