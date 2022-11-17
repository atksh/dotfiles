#!/bin/bash
set -eux

### CONFIG ###
GOVERSION=1.19.3
OS=linux
ARCH=amd64
SINGULARITY_VERSION=3.8.4
OPENSSL_VERSION=1.1.1s
LIBFFI_VERSION=3.4.4
SQLITE_YEAR=2022
SQLITE_VERSION=3400000
PYTHON_VERSION=3.9.14
### END ###


workspace=/tmp/$(uuidgen)
prefix=$HOME/.local

export PATH="$PATH:$HOME/.local/bin"
export LD_LIBRARY_PATH="$HOME/.local/lib"

mkdir -p $workspace
mkdir -p $prefix
rm -rf $prefix/* || true

# install GO
cd $workspace
wget -O $prefix/go${GOVERSION}.${OS}-${ARCH}.tar.gz \
  https://dl.google.com/go/go${GOVERSION}.${OS}-${ARCH}.tar.gz
tar -C $prefix -xzf $prefix/go${GOVERSION}.${OS}-${ARCH}.tar.gz
rm $prefix/go${GOVERSION}.${OS}-${ARCH}.tar.gz
export PATH="$PATH:$prefix/go/bin"

# install singularity
cd $workspace
git clone --branch v${SINGULARITY_VERSION} --depth=1 https://github.com/hpcng/singularity.git
cd singularity
./mconfig -p $prefix --without-suid
cd ./builddir
make -j$(nproc)
make install

# install openssl
cd $workspace
wget -O openssl-${OPENSSL_VERSION}.tar.gz \
  https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
tar -C $workspace -xzf $workspace/openssl-${OPENSSL_VERSION}.tar.gz
cd openssl-${OPENSSL_VERSION}
./config --prefix=$prefix/openssl --openssldir=$prefix/openssl shared zlib
make -j1 depend
make -j$(nproc)
make install_sw

# install libffid
cd $workspace
wget -O libffi-${LIBFFI_VERSION}.tar.gz \
  https://github.com/libffi/libffi/releases/download/v${LIBFFI_VERSION}/libffi-${LIBFFI_VERSION}.tar.gz
tar xvfz libffi-${LIBFFI_VERSION}.tar.gz
cd libffi-${LIBFFI_VERSION}
./configure --prefix=$prefix --disable-docs
make -j$(nproc)
make install

# install sqlite3
cd $workspace
wget -O sqlite-autoconf-${SQLITE_VERSION}.tar.gz \
  https://www.sqlite.org/${SQLITE_YEAR}/sqlite-autoconf-${SQLITE_VERSION}.tar.gz
tar -zxvf sqlite-autoconf-${SQLITE_VERSION}.tar.gz
cd sqlite-autoconf-${SQLITE_VERSION}
./configure --prefix=$prefix
make -j$(nproc)
make install

# install python
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
ln -s $prefix/bin/pip $prefix/bin/pip3

# install aws cli
rm -rf $HOME/.aws || true
pip install -U pip setuptools wheel --no-cache-dir
pip install https://github.com/boto/botocore/archive/v2.tar.gz --no-cache-dir
pip install https://github.com/aws/aws-cli/archive/v2.tar.gz --no-cache-dir
mkdir $HOME/.aws
touch $HOME/.aws/credentials
touch $HOME/.aws/config
echo "[default]" >> $HOME/.aws/credentials
echo "aws_access_key_id=" >> $HOME/.aws/credentials
echo "aws_secret_access_key=" >> $HOME/.aws/credentials
echo "[default]" >> $HOME/.aws/config
echo "region=ap-northeast-1" >> $HOME/.aws/config
echo "output=json" >> $HOME/.aws/config

# clean up
rm -rf $workspace

# env
cd ~
touch $HOME/.bash_profile

echo "export PATH=${prefix}/go/bin:\$PATH" >> $HOME/.bash_profile
echo "export PATH=${prefix}/bin:\$PATH" >> $HOME/.bash_profile
echo "export LD_LIBRARY_PATH=${prefix}/lib:\$LD_LIBRARY_PATH" >> $HOME/.bash_profile

source $HOME/.bash_profile
