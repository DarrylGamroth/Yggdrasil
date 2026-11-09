using BinaryBuilder

name = "PipeWireAOQueue"
version = v"0.1.0"

sources = [
    GitSource(
        "https://github.com/DarrylGamroth/pipewireao-spa-plugins-core.git",
        "a8f24e182590087d2d0a49dff63ed728a587c269",
    ),
]

script = raw"""
cd ${WORKSPACE}/srcdir/pipewireao-spa-plugins-core

meson setup builddir \
    --buildtype=release \
    --cross-file=${MESON_TARGET_TOOLCHAIN} \
    --prefix=${prefix} \
    -Dqueue-only=true \
    -Dtests=disabled

meson compile -C builddir -j${nproc}
meson install -C builddir
install_license LICENSE
"""

platforms = [Platform(arch, "linux"; libc="glibc") for arch in ("aarch64", "x86_64")]
products = [
    FileProduct("lib/pipewire-ao-0.3/libpipewire-module-queue.so", :libpipewire_module_queue),
]
dependencies = [Dependency("PipeWireAO_jll", v"4.0.2"; compat="~4.0.2")]

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.10", preferred_gcc_version=v"11",
)
