
set -ex

TARGET=x86_64-linux-gnu
OUT=/opt/chain/gcc4.7.4
THREADS=$(nproc --all)
rm -rf build glibc $OUT
mkdir -p build glibc tar $OUT
cd tar
set +x
[ ! -f ./gcc-4.7.4.tar.gz ]     && wget https://ftp.gnu.org/gnu/gcc/gcc-4.7.4/gcc-4.7.4.tar.gz
[ ! -f ./binutils-2.25.tar.gz ] && wget http://ftpmirror.gnu.org/binutils/binutils-2.25.tar.gz
[ ! -f ./linux-4.2.3.tar.xz ] && wget https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.2.3.tar.xz
[ ! -f ./glibc-2.21.tar.xz ]    && wget http://ftpmirror.gnu.org/glibc/glibc-2.21.tar.xz

[ ! -d ./gcc-4.7.4 ]     && tar xf gcc-4.7.4.tar.gz
[ ! -d ./binutils-2.25 ] && tar xf binutils-2.25.tar.gz
[ ! -d ./linux-4.2.3 ] && tar xf linux-4.2.3.tar.xz
[ ! -d ./glibc-2.21 ]    && tar xf glibc-2.21.tar.xz

set -x
cd linux-4.2.3
make INSTALL_HDR_PATH=$OUT/$TARGET headers_install 1> /dev/null
cd ..

rm -rf build-binutils
mkdir -p build-binutils
cd build-binutils
../binutils-2.25/configure --prefix=$OUT --target=$TARGET --disable-nls --with-system-zlib 1> /dev/null
make -j$THREADS 1> /dev/null
make install 1> /dev/null
cd ..

cd gcc-4.7.4
./contrib/download_prerequisites
cd ../..

cd build
../tar/gcc-4.7.4/configure --prefix=$OUT --enable-languages=c,c++ --enable-multilib 1> /dev/null
make -j$THREADS all-gcc 1> /dev/null
make install-gcc 1> /dev/null
cd ..

cd glibc
../tar/glibc-2.21/configure --prefix=$OUT/$TARGET --build=$MACHTYPE --with-headers=$OUT/$TARGET/include  libc_cv_forced_unwind=yes --enable-multilib  1> /dev/null
make install-bootstrap-headers=yes install-headers 1> /dev/null
make -j$THREADS csu/subdir_lib 1> /dev/null
mkdir -p $OUT/$TARGET/lib 1> /dev/null
install csu/crt1.o csu/crti.o csu/crtn.o $OUT/$TARGET/lib 1> /dev/null
gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $OUT/$TARGET/lib/libc.so 1> /dev/null
touch $OUT/$TARGET/include/gnu/stubs.h 1> /dev/null
cd ..

cd build
make -j$THREADS all-target-libgcc 1> /dev/null
make install-target-libgcc 1> /dev/null
cd ..

cd glibc
make -j$THREADS 1> /dev/null
make install 1> /dev/null
cd ..

cd build
make -j$THREADS 1> /dev/null
make install 1> /dev/null
cd ..
