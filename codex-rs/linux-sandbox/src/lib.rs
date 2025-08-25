#[cfg(any(target_os = "linux", target_os = "android"))]
mod landlock;
#[cfg(any(target_os = "linux", target_os = "android"))]
mod linux_run_main;

#[cfg(any(target_os = "linux", target_os = "android"))]
pub fn run_main() -> ! {
    linux_run_main::run_main();
}

#[cfg(not(any(target_os = "linux", target_os = "android")))]
pub fn run_main() -> ! {
    panic!("codex-linux-sandbox is only supported on Linux and Android");
}
