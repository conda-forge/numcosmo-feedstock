#!/usr/bin/env bash

_PY=$PYTHON
export PYTHON="python"
export CPPFLAGS="$CPPFLAGS -I${PREFIX}/include"

./configure --prefix="${PREFIX}" --enable-opt-cflags

make -j$CPU_COUNT
#make check VERBOSE=1 -j$CPU_COUNT
make install -j$CPU_COUNT

