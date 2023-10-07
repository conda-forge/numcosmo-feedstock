#!/usr/bin/env bash

set -ex

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .

_PY=$PYTHON
export PYTHON="python"
export CPPFLAGS="$CPPFLAGS -I${PREFIX}/include"
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$PREFIX/lib/pkgconfig:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$(which pkg-config)

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

