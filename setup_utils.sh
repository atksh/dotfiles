#!/bin/bash
set -eux -o pipefail

### CONFIG ###
GOVERSION=1.19.3
OS=linux
ARCH=amd64
SECCOMP_VERSION=2.5.4
GPERF_VERSION=3.1
SINGULARITY_VERSION=3.8.4
OPENSSL_VERSION=1.1.1s
LIBFFI_VERSION=3.4.4
SQLITE_YEAR=2022
SQLITE_VERSION=3400000
PYTHON_VERSION=3.10.9
BZIP_VERSION=1.0.8
### END ###

workspace=$(mktemp -d)
prefix=$HOME/.local
rm -rf $prefix/*

export PATH="$PATH:$HOME/.local/bin"
export LD_LIBRARY_PATH="$HOME/.local/lib"

mkdir -p $prefix

# install go
install_go() {
  pushd $workspace
  rm -rf go
  wget -O $prefix/go${GOVERSION}.${OS}-${ARCH}.tar.gz \
    https://dl.google.com/go/go${GOVERSION}.${OS}-${ARCH}.tar.gz
  tar -C $prefix -xzf $prefix/go${GOVERSION}.${OS}-${ARCH}.tar.gz
  rm $prefix/go${GOVERSION}.${OS}-${ARCH}.tar.gz
  popd
}

install_singularity() {
  export PATH="$PATH:$prefix/go/bin"
  pushd $workspace
  git clone --branch v${SINGULARITY_VERSION} --depth=1 https://github.com/sylabs/singularity.git
  cd singularity
  ./mconfig -p $prefix --without-suid
  cd ./builddir
  make -j$(nproc)
  make install
  popd
}

instal_openssl() {
  pushd $workspace
  wget -O openssl-${OPENSSL_VERSION}.tar.gz \
    https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
  tar -C $workspace -xzf $workspace/openssl-${OPENSSL_VERSION}.tar.gz
  cd openssl-${OPENSSL_VERSION}
  ./config --prefix=$prefix/openssl --openssldir=$prefix/openssl shared zlib
  make -j1 depend
  make -j$(nproc)
  make install_sw
  popd
}

install_sqlite3() {
  pushd $workspace
  wget -O sqlite-autoconf-${SQLITE_VERSION}.tar.gz \
    https://www.sqlite.org/${SQLITE_YEAR}/sqlite-autoconf-${SQLITE_VERSION}.tar.gz
  tar -zxvf sqlite-autoconf-${SQLITE_VERSION}.tar.gz
  cd sqlite-autoconf-${SQLITE_VERSION}
  ./configure --prefix=$prefix
  make -j$(nproc)
  make install
  popd
}

install_libffi() {
  pushd $workspace
  wget -O libffi-${LIBFFI_VERSION}.tar.gz \
    https://github.com/libffi/libffi/releases/download/v${LIBFFI_VERSION}/libffi-${LIBFFI_VERSION}.tar.gz
  tar xvfz libffi-${LIBFFI_VERSION}.tar.gz
  cd libffi-${LIBFFI_VERSION}
  ./configure --prefix=$prefix --disable-docs
  make -j$(nproc)
  make install
  popd
}

install_bzip2() {
  pushd $workspace
  wget -O bzip2-${BZIP_VERSION}.tar.gz \
    https://sourceware.org/pub/bzip2/bzip2-${BZIP_VERSION}.tar.gz
  tar xvfz bzip2-${BZIP_VERSION}.tar.gz
  cd bzip2-${BZIP_VERSION}
  make -j$(nproc)
  make -f Makefile-libbz2_so
  make install PREFIX=$prefix
  popd
}

install_python() {
  pushd $workspace
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
  rm -f $prefix/bin/python
  ln -s $prefix/bin/python3 $prefix/bin/python
  popd
}

install_awscliv2() {
  pushd $workspace
  rm -rf $HOME/.aws
  pip install -U pip setuptools wheel --no-cache-dir
  pip install https://github.com/boto/botocore/archive/v2.tar.gz --no-cache-dir
  pip install https://github.com/aws/aws-cli/archive/v2.tar.gz --no-cache-dir
  mkdir $HOME/.aws
  touch $HOME/.aws/credentials
  touch $HOME/.aws/config
  echo "[default]" >>$HOME/.aws/credentials
  echo "aws_access_key_id=" >>$HOME/.aws/credentials
  echo "aws_secret_access_key=" >>$HOME/.aws/credentials
  echo "[default]" >>$HOME/.aws/config
  echo "region=ap-northeast-1" >>$HOME/.aws/config
  echo "output=json" >>$HOME/.aws/config
  popd
}

cleanup() {
  rm -rf $workspace
}

set_env() {
  pushd $HOME
  rm -f $HOME/.bash_profile
  touch $HOME/.bash_profile
  echo "export PATH=${prefix}/go/bin:\$PATH" >>$HOME/.bash_profile
  echo "export PATH=${prefix}/bin:\$PATH" >>$HOME/.bash_profile
  echo "export LD_LIBRARY_PATH=${prefix}/lib:\$LD_LIBRARY_PATH" >>$HOME/.bash_profile
  source $HOME/.bash_profile
}

# singularity
install_go
install_singularity
# python
instal_openssl &
install_libffi &
install_sqlite3 &
install_bzip2 &
wait
install_python
# utils
install_awscliv2

# post process
cleanup
set_env

echo "Execute $(source ~/.bash_profile) to set PATH"
