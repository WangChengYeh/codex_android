TERMUX_PKG_HOMEPAGE=https://github.com/WangChengYeh/codex_android
TERMUX_PKG_DESCRIPTION="Android Codex CLI 0.25.0 for Termux - AI-powered coding assistant"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@WangChengYeh"
TERMUX_PKG_VERSION=0.25.0
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL=https://github.com/WangChengYeh/codex_android/archive/refs/tags/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=SKIP_CHECKSUM
TERMUX_PKG_DEPENDS="libc++, openssl"
TERMUX_PKG_BUILD_DEPENDS="rust"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=false

termux_step_configure() {
    termux_setup_rust
    export CARGO_BUILD_TARGET=aarch64-linux-android
    export RUSTFLAGS="-C linker=$CC"
}

termux_step_make() {
    cd codex-rs
    cargo build --release --target aarch64-linux-android
}

termux_step_make_install() {
    install -Dm755 "codex-rs/target/aarch64-linux-android/release/codex" "$TERMUX_PREFIX/bin/codex"
    install -Dm755 "codex-rs/target/aarch64-linux-android/release/codex-exec" "$TERMUX_PREFIX/bin/codex-exec"
}