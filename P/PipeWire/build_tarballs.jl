using BinaryBuilder, Pkg

name = "PipeWire"
version = v"1.6.8"

sources = [
    GitSource(
        "https://gitlab.freedesktop.org/pipewire/pipewire.git",
        "b741e0c74f5436f0c925f7741140db0efd32cf4e",
    ),
    DirectorySource("./bundled"),
]

# Build the client library and the dependency-free SPA modules needed by
# PipeWire clients. Integrations with host audio/video stacks belong to the
# host PipeWire installation and are deliberately excluded from this artifact.
script = raw"""
cd ${WORKSPACE}/srcdir/pipewire
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/binarybuilder-compat.patch

meson setup builddir \
    --buildtype=release \
    --cross-file=${MESON_TARGET_TOOLCHAIN} \
    --prefix=${prefix} \
    -Dauto_features=disabled \
    -Dexamples=disabled \
    -Dtests=disabled \
    -Dinstalled_tests=disabled \
    -Dpipewire-jack=disabled \
    -Dpipewire-v4l2=disabled \
    -Ddbus=disabled \
    -Dflatpak=disabled \
    -Dsession-managers=[] \
    -Dlegacy-rtkit=false \
    -Drlimits-install=false

meson compile -C builddir -j${nproc}
meson install -C builddir
install_license LICENSE
"""

# PipeWire is a Linux-native IPC and multimedia service. This package targets
# glibc-based systems; musl distributions such as Alpine are out of scope.
platforms = filter(p -> Sys.islinux(p) && libc(p) == "glibc", supported_platforms())

products = [
    LibraryProduct("libpipewire-0.3", :libpipewire),
    LibraryProduct(
        "libspa-support",
        :libspa_support,
        "lib/spa-0.2/support";
        dont_dlopen=true,
    ),
]

dependencies = []

# PipeWire discovers support modules and configuration at runtime. Preserve an
# explicit caller override while making artifact-contained defaults relocatable.
init_block = raw"""
ENV["SPA_PLUGIN_DIR"] = get(ENV, "SPA_PLUGIN_DIR", joinpath(artifact_dir, "lib", "spa-0.2"))
ENV["PIPEWIRE_MODULE_DIR"] = get(ENV, "PIPEWIRE_MODULE_DIR", joinpath(artifact_dir, "lib", "pipewire-0.3"))
ENV["PIPEWIRE_CONFIG_DIR"] = get(ENV, "PIPEWIRE_CONFIG_DIR", joinpath(artifact_dir, "share", "pipewire"))
"""

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    init_block,
    julia_compat="1.10",
    preferred_gcc_version=v"11",
)
