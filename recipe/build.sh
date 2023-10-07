#!/usr/bin/env bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .

_PY=$PYTHON
export PYTHON="python"
export CPPFLAGS="$CPPFLAGS -I${PREFIX}/include"

./configure --prefix="${PREFIX}" --enable-opt-cflags || cat config.log || false

make -j$CPU_COUNT
#make check VERBOSE=1 -j$CPU_COUNT
make install -j$CPU_COUNT

