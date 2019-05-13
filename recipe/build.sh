#!/usr/bin/env bash

set -ex

if [ -n "$OS_LINUX" ]; then
  arches="default avx2"
else
  arches="default"
fi

to_link=""
for arch in $arches ; do
  arch_flag=""
  if [ "$arch" == "avx2" ]; then
    arch_flag="-mavx2"
  fi
  tmp_obj=bitshuffle_${arch}_tmp.o
  dst_obj=bitshuffle_${arch}.o
  
  ${CC:-gcc} $EXTRA_CFLAGS $arch_flag -std=c99 -I$PREFIX/include -O3 -DNDEBUG -fPIC -c \
    "src/bitshuffle_core.c" \
    "src/bitshuffle.c" \
    "src/iochain.c"
  
  # Merge the object files together to produce a combined .o file.
  ld -r -o $tmp_obj bitshuffle_core.o bitshuffle.o iochain.o

  # For the AVX2 symbols, suffix them.
  if [ "$arch" == "avx2" ]; then
    # Create a mapping file with '<old_sym> <suffixed_sym>' on each line.
    nm --defined-only --extern-only $tmp_obj | while read addr type sym ; do
      echo ${sym} ${sym}_${arch}
    done > renames.txt
    objcopy --redefine-syms=renames.txt $tmp_obj $dst_obj
  else
    mv $tmp_obj $dst_obj
  fi
  to_link="$to_link $dst_obj"
done

rm -f bitshuffle.a
ar rs bitshuffle.a $to_link
cp bitshuffle.a $PREFIX/lib/

cp src/bitshuffle.h $PREFIX/include/bitshuffle.h
cp src/bitshuffle_core.h $PREFIX/include/bitshuffle_core.h

HDF5_DIR=$PREFIX $PYTHON -m pip install . --no-deps -vv
