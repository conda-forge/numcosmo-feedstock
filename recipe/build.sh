#!/usr/bin/env bash

set -exuo pipefail

meson_config_args=(
     --backend=ninja
)

_PY=$PYTHON
export PYTHON="python"
export CPPFLAGS="$CPPFLAGS -I${PREFIX}/include"
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$PREFIX/lib/pkgconfig:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$(which pkg-config)

# Workaround to use the right lto plugins

# This should transform the last occurrence of 'ar' into 'gcc-ar'
[[ $AR != *gcc* && $AR == *ar* ]] && export GCC_AR="${AR%ar}gcc-ar${AR##*ar}"
[[ -e $GCC_AR ]] && AR=$GCC_AR

# This should transform the last occurrence of 'nm' into 'gcc-nm'
[[ $NM != *gcc* && $NM == *nm* ]] && export GCC_NM="${NM%nm}gcc-nm${NM##*nm}"
[[ -e $GCC_NM ]] && NM=$GCC_NM

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == 1 ]]; then
  unset _CONDA_PYTHON_SYSCONFIGDATA_NAME
  (
    export CC=$CC_FOR_BUILD
    export FC=$FC_FOR_BUILD
    export F77=$FC_FOR_BUILD
    export AR="$($CC_FOR_BUILD -print-prog-name=ar)"
    export NM="$($CC_FOR_BUILD -print-prog-name=nm)"
    export LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX}
    export PKG_CONFIG_PATH=${BUILD_PREFIX}/lib/pkgconfig

    # Workaround to use the right lto plugins

    # This should transform the last occurrence of 'ar' into 'gcc-ar'
    [[ $AR != *gcc* && $AR == *ar* ]] && export GCC_AR="${AR%ar}gcc-ar${AR##*ar}"
    [[ -e $GCC_AR ]] && AR=$GCC_AR

    # This should transform the last occurrence of 'nm' into 'gcc-nm'
    [[ $NM != *gcc* && $NM == *nm* ]] && export GCC_NM="${NM%nm}gcc-nm${NM##*nm}"
    [[ -e $GCC_NM ]] && NM=$GCC_NM

    # Unset them as we're ok with builds that are either slow or non-portable
    unset CFLAGS
    unset CPPFLAGS
    unset CXXFLAGS
    unset FCFLAGS
    unset FFLAGS
    export host_alias=$build_alias

    meson setup native-build \
        "${meson_config_args[@]}" \
        --prefix="$BUILD_PREFIX" \
        -Dintrospection=enabled \
        -Dnumcosmo_py=true -Db_lto=false \
        -Dlocalstatedir="$BUILD_PREFIX/var" \
        || { cat native-build/meson-logs/meson-log.txt ; exit 1 ; }

    # This script would generate the functions.txt and dump.xml and save them
    # This is loaded in the native build. We assume that the functions exported
    # by glib are the same for the native and cross builds
    export GI_CROSS_LAUNCHER=$GIR_PREFIX/libexec/gi-cross-launcher-save.sh
    ninja -C native-build -j${CPU_COUNT}
    ninja -C native-build install

    # Store generated introspection information
    mkdir -p introspection/lib
    cp -ap $BUILD_PREFIX/lib/girepository-1.0 introspection/lib
    mkdir -p introspection/share
    cp -ap $BUILD_PREFIX/share/gir-1.0 introspection/share
  )
  export GI_CROSS_LAUNCHER=$GIR_PREFIX/libexec/gi-cross-launcher-load.sh
  export MESON_ARGS="${MESON_ARGS} -Dintrospection=disabled"
else
  export MESON_ARGS="${MESON_ARGS} -Dintrospection=enabled"
fi

meson setup builddir \
    ${MESON_ARGS} \
    "${meson_config_args[@]}" \
    --prefix="$PREFIX" \
    -Dlocalstatedir="$PREFIX/var" \
    -Dnumcosmo_py=true -Db_lto=false \
    || { cat builddir/meson-logs/meson-log.txt ; exit 1 ; }

ninja -C builddir -j${CPU_COUNT} -v
