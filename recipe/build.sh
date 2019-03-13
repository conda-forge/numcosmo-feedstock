#!/usr/bin/env bash

_PY=$PYTHON
export PYTHON="python"

./configure --prefix="${PREFIX}" --enable-opt-cflags

make V=1 -j$CPU_COUNT
#make check VERBOSE=1 -j$CPU_COUNT
make install -j$CPU_COUNT
