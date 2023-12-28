#!/usr/bin/env bash

set -ex

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

if [ "${CONDA_BUILD_CROSS_COMPILATION}" = "1" ]; then
  unset _CONDA_PYTHON_SYSCONFIGDATA_NAME
  (
    mkdir -p native-build
    cd native-build

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
    [[ -e $GCC_NM ]] && AR=$GCC_NM

    # Unset them as we're ok with builds that are either slow or non-portable
    unset CFLAGS
    unset CPPFLAGS
    unset CXXFLAGS
    unset FCFLAGS
    unset FFLAGS
    export host_alias=$build_alias

    meson setup -Dnumcosmo_py=true --libdir=$BUILD_PREFIX/lib --prefix=$BUILD_PREFIX || (cat meson-logs/meson-log.txt && exit 1)

    # This script would generate the functions.txt and dump.xml and save them
    # This is loaded in the native build. We assume that the functions exported
    # by the package are the same for the native and cross builds
    export GI_CROSS_LAUNCHER=$BUILD_PREFIX/libexec/gi-cross-launcher-save.sh
    meson compile -j$CPU_COUNT
    meson install
  )
  export GI_CROSS_LAUNCHER=$BUILD_PREFIX/libexec/gi-cross-launcher-load.sh
fi


meson setup ${MESON_ARGS:---libdir=$PREFIX/lib} builddir --prefix=$PREFIX -Dintrospection=enabled -Dnumcosmo_py=true || (cat builddir/meson-logs/meson-log.txt && exit 1)
meson compile -C builddir -j$CPU_COUNT
meson install -C builddir
python -m pip install --no-deps --ignore-installed . -vvv


