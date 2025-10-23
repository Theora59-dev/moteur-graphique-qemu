#![no_std]
#![no_main]

use core::fmt::Write;
use core::panic::PanicInfo;
use uefi::prelude::*;
use uefi::proto::console::gop::GraphicsOutput;
use uefi::table::runtime::Time;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

#[entry]
fn main(_image_handle: Handle, mut system_table: SystemTable<Boot>) -> Status {
    let gop_ptr = system_table
        .boot_services()
        .locate_protocol::<GraphicsOutput>()
        .unwrap()
        .unwrap();
    let gop = unsafe { &mut *gop_ptr.get() };
    let mode = 0;
    let mode_info = gop.modes().nth(mode).unwrap().unwrap();
    let _ = gop.set_mode(&mode_info).unwrap(); // Réinitialiser la console texte
    let _ = system_table.stdout().reset(false);

    // Obtenir l'heure initiale
    let mut last_time: Time = system_table.runtime_services().get_time().unwrap().unwrap();
    let mut count = 0u32;

    // Récupérer le protocole graphique

    let (width, height) = gop.current_mode_info().resolution();

    // Récupérer le framebuffer et convertir en slice mutable
    let mut frame = gop.frame_buffer();
    let frame_ptr = frame.as_mut_ptr();
    let frame_len = frame.size();

    loop {
        // Obtenir l'heure actuelle
        let current_time: Time = system_table.runtime_services().get_time().unwrap().unwrap();

        // Afficher le FPS toutes les secondes
        if current_time.second() != last_time.second() {
            let _ = writeln!(
                system_table.stdout(),
                "Taux de rafraîchissement réel: {} Hz, temps: {}",
                count,
                current_time.second()
            );
            count = 0;
            last_time = current_time;
        }

        let red = [
            (current_time.second()) % 255,
            (current_time.second()) % 255,
            0,
            0,
        ]; // (B,G,R,Nothing)
        for x in 0..width {
            for y in 0..height {
                set_pixel(frame_ptr, frame_len, width, x, y, red);
            }
        }
        count += 1;

        // Petit délai pour ne pas saturer le CPU
        system_table.boot_services().stall(4_080); // 4 ms
    }
}

fn set_pixel(
    frame_ptr: *mut u8,
    frame_len: usize,
    width: usize,
    x: usize,
    y: usize,
    color: [u8; 4],
) {
    let index = (y * width + x) * 4;
    if index + 4 <= frame_len {
        unsafe {
            core::ptr::copy_nonoverlapping(color.as_ptr(), frame_ptr.add(index), 4);
        }
    }
}
