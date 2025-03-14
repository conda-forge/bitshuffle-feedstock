#!/usr/bin/env bash

set -ex

tmp_obj=bitshuffle_default_tmp.o
dst_obj=bitshuffle_default.o

$CC $CFLAGS $EXTRA_CFLAGS -std=c99 -I$PREFIX/include -DNDEBUG -c \
  "src/bitshuffle_core.c" \
  "src/bitshuffle.c" \
  "src/iochain.c"

# Merge the object files together to produce a combined .o file.
ld -r -o $tmp_obj bitshuffle_core.o bitshuffle.o iochain.o

mv $tmp_obj $dst_obj
to_link="$to_link $dst_obj"

rm -f bitshuffle.a
ar rs bitshuffle.a $to_link
cp bitshuffle.a $PREFIX/lib/

cp src/bitshuffle.h $PREFIX/include/bitshuffle.h
cp src/bitshuffle_core.h $PREFIX/include/bitshuffle_core.h

if [[ $HOST_PLATFORM = osx-arm64 ]]; then
    # Bitshuffle forces usage of -mcpu=, defaulting to the invalid "native"
    export BITSHUFFLE_ARCH=apple-m1
fi

HDF5_DIR=$PREFIX $PYTHON -m pip install . --no-deps -vv
