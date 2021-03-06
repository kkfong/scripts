#!/bin/sh

set -e
set -v

gcc_ver=5.2.0
gcc_dir=gcc-$gcc_ver
gcc_pkg=${gcc_dir}.tar.bz2
gcc_url="http://ftp.gnu.org/gnu/gcc/gcc-$gcc_ver/$gcc_pkg"

mpfr_dir=mpfr-3.1.3
mpc_dir=mpc-1.0.3
gmp_dir=gmp-6.1.0
mpfr_pkg=${mpfr_dir}.tar.xz
mpc_pkg=${mpc_dir}.tar.gz
gmp_pkg=${gmp_dir}.tar.xz
mpfr_url="http://www.mpfr.org/mpfr-current/$mpfr_pkg"
mpc_url="http://ftp.gnu.org/gnu/mpc/$mpc_pkg"
gmp_url="https://gmplib.org/download/gmp/$gmp_pkg"

wget $gcc_url
tar xf $gcc_pkg
rm $gcc_pkg
mv $gcc_dir ${gcc_dir}-src
cd ${gcc_dir}-src

wget $mpfr_url
tar xf $mpfr_pkg
mv $mpfr_dir mpfr

wget $mpc_url
tar xf $mpc_pkg
mv $mpc_dir mpc

wget $gmp_url
tar xf $gmp_pkg
mv $gmp_dir gmp

export CFLAGS="-g -O2 -fstack-protector -ffunction-sections -fdata-sections"
export CXXFLAGS="-g -O2 -fstack-protector -ffunction-sections -fdata-sections"
export LDFLAGS="-Wl,-z,relro -Wl,--gc-sections"

./configure --prefix="$HOME/$gcc_dir" --with-pic=yes
make -j4
make install

cd ..
rm -rf ${gcc_dir}-src

set +e

strip $gcc_dir/bin/* 2>/dev/null
strip $gcc_dir/lib/gcc/*-linux-gnu/$gcc_ver/plugin/lib*.so.* 2>/dev/null
strip $gcc_dir/lib*/lib*.so.* 2>/dev/null
strip $gcc_dir/libexec/gcc/*-linux-gnu/$gcc_ver/* 2>/dev/null
strip $gcc_dir/libexec/gcc/*-linux-gnu/$gcc_ver/*/* 2>/dev/null

#strip --strip-debug $gcc_dir/lib*/lib*.a 2>/dev/null
#strip --strip-debug $gcc_dir/lib/gcc/*-linux-gnu/$gcc_ver/lib*.a 2>/dev/null
#strip --strip-debug $gcc_dir/lib/gcc/*-linux-gnu/$gcc_ver/*/lib*.a 2>/dev/null

find $gcc_dir/share/info -type f -exec gzip -f9 '{}' \;
find $gcc_dir/share/man -type f -exec gzip -f9 '{}' \;


cat <<EOF> $gcc_dir/env.sh
#!/bin/sh

cd "\$(dirname "\$0")"

cat <<EOL
export PATH="\$PWD/bin:\\\$PATH"
export LDFLAGS="-static-libgcc -static-libstdc++ \\\$LDFLAGS"
EOL
EOF
chmod a+x $gcc_dir/env.sh

