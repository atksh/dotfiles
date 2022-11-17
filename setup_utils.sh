#!/bin/bash
set -eux

workspace=/tmp/$(uuidgen)
prefix=$HOME/.local

export PATH="$PATH:$HOME/.local/bin"
export LD_LIBRARY_PATH="$HOME/.local/lib"

mkdir -p $workspace
mkdir -p $prefix
rm -rf $prefix/* || true

# # install GO
GOVERSION=1.17.3 OS=linux ARCH=amd64  # change this as you need

cd $workspace
wget -O $prefix/go${GOVERSION}.${OS}-${ARCH}.tar.gz \
  https://dl.google.com/go/go${GOVERSION}.${OS}-${ARCH}.tar.gz
tar -C $prefix -xzf $prefix/go${GOVERSION}.${OS}-${ARCH}.tar.gz
rm $prefix/go${GOVERSION}.${OS}-${ARCH}.tar.gz
export PATH="$PATH:$prefix/go/bin"

# install singularity
cd $workspace
git clone --branch v3.8.4 --depth=1 https://github.com/hpcng/singularity.git
cd singularity
./mconfig -p $prefix --without-suid
cd ./builddir
make -j$(nproc)
make install

# install openssl
OPENSSL_VERSION=1.1.1o
# 
cd $workspace
wget -O openssl-${OPENSSL_VERSION}.tar.gz \
  https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
tar -C $workspace -xzf $workspace/openssl-${OPENSSL_VERSION}.tar.gz
cd openssl-${OPENSSL_VERSION}
./config --prefix=$prefix/openssl --openssldir=$prefix/openssl shared zlib
make -j1 depend
make -j$(nproc)
make install_sw

# install libffi
LIBFFI_VERSION=3.4.2

cd $workspace
wget -O libffi-${LIBFFI_VERSION}.tar.gz \
  https://github.com/libffi/libffi/releases/download/v${LIBFFI_VERSION}/libffi-${LIBFFI_VERSION}.tar.gz
tar xvfz libffi-${LIBFFI_VERSION}.tar.gz
cd libffi-${LIBFFI_VERSION}
./configure --prefix=$prefix --disable-docs
make -j$(nproc)
make install

# install python
PYTHON_VERSION=3.10.4

cd $workspace
wget -O Python-${PYTHON_VERSION}.tar.xz \
  https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz
xz -dv $workspace/Python-${PYTHON_VERSION}.tar.xz
tar xvf Python-${PYTHON_VERSION}.tar

cd Python-${PYTHON_VERSION}
export LDFLAGS="-L$prefix/lib"
export CPPFLAGS="-I $prefix/include"
export PKG_CONFIG_PATH="$prefix/lib/pkgconfig"

./configure -C \
  --prefix=$prefix \
  --with-openssl=$prefix/openssl \
  --with-openssl-rpath=auto \
  --with-system-ffi \
  --enable-shared \
  --enable-loadable-sqlite-extensions \
  --without-ensurepip
make -j$(nproc)
make install
wget -O get-pip.py \
  https://bootstrap.pypa.io/get-pip.py
$prefix/bin/python3 get-pip.py --user

rm $prefix/bin/python || true
ln -s $prefix/bin/python3 $prefix/bin/python

# install aws cli
pip install -U pip setuptools wheel
pip install https://github.com/boto/botocore/archive/v2.tar.gz
pip install https://github.com/aws/aws-cli/archive/v2.tar.gz

# env
echo "export PATH=\$PATH:$HOME/.local/bin" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$HOME/.local/lib" >> ~/.bashrc

# clean up
rm -rf $workspace
rm -rf $prefix/go
