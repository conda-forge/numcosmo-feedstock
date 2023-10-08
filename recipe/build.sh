#!/usr/bin/env bash

set -ex

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .

_PY=$PYTHON
export PYTHON="python"
export CPPFLAGS="$CPPFLAGS -I${PREFIX}/include"
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$PREFIX/lib/pkgconfig:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$(which pkg-config)

if [ "${CONDA_BUILD_CROSS_COMPILATION}" = "1" ]; then
  unset _CONDA_PYTHON_SYSCONFIGDATA_NAME
  (
    mkdir -p native-build
    cd native-build

    export CC=$CC_FOR_BUILD
    export FC=$GFORTRAN_FOR_BUILD
    export F77=$GFORTRAN_FOR_BUILD
    export AR="$($CC_FOR_BUILD -print-prog-name=ar)"
    export NM="$($CC_FOR_BUILD -print-prog-name=nm)"
    export LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX}
    export PKG_CONFIG_PATH=${BUILD_PREFIX}/lib/pkgconfig

    # Unset them as we're ok with builds that are either slow or non-portable
    unset CFLAGS
    unset CPPFLAGS
    export host_alias=$build_alias

    ../configure --prefix="${PREFIX}" \
                 --host=${HOST}       \
                 --build=${BUILD}     \
                 --enable-opt-cflags  \
                 || (cat config.log; false)

    # This script would generate the functions.txt and dump.xml and save them
    # This is loaded in the native build. We assume that the functions exported
    # by the package are the same for the native and cross builds
    export GI_CROSS_LAUNCHER=$BUILD_PREFIX/libexec/gi-cross-launcher-save.sh
    make -j$CPU_COUNT
    make install -j$CPU_COUNT
  )
  export GI_CROSS_LAUNCHER=$BUILD_PREFIX/libexec/gi-cross-launcher-load.sh
fi

./configure --prefix="${PREFIX}" \
            --host=${HOST}       \
            --build=${BUILD}     \
            --enable-opt-cflags  \
            || (cat config.log; false)

make -j$CPU_COUNT
# if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" ]]; then
#   make check VERBOSE=1 -j$CPU_COUNT
# fi

make install -j$CPU_COUNT

