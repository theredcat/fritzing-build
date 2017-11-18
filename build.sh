#!/bin/bash

version_fritzing=0.9.3b
version_libssh2=libssh2-1.8.0
version_libgit2=v0.23.4
version_qt=v5.9.2
version_openssl=OpenSSL_1_0_2k

offline=false

set -e
set -x
rootpath=$(pwd -P)

git_fritzing=https://github.com/fritzing/fritzing-app.git
git_openssl=https://github.com/openssl/openssl.git
git_libssh2=https://github.com/libssh2/libssh2.git
git_libgit2=https://github.com/libgit2/libgit2.git
git_qt=https://github.com/qt/qt5.git

clone_version () {
	cd $rootpath
	if ! test -d git-$1; then
		if ! $offline; then
			git clone $2 git-$1
		else
			echo "Offline mode activated but repository $1 is not present"
			exit 1
		fi
	fi
	cd git-$1 && git checkout $3
	if ! $offline; then
		git fetch
	fi
	cd $rootpath
}

# Clone and checkout fritzing
clone_version fritzing $git_fritzing $version_fritzing

# Clone and checkout libgit2
clone_version libgit2 $git_libgit2 $version_libgit2

# Clone and checkout libssh2
clone_version libssh2 $git_libssh2 $version_libssh2

# Clone and checkout openssl
clone_version openssl $git_openssl $version_openssl

# Clone and checkout ssl
clone_version qt $git_qt $version_qt

# Build openssl
cd $rootpath/git-openssl
git clean -fn && git clean -Xfn
./config --prefix=$rootpath/openssl && make && make install
cd $rootpath

# Build libssh2
cd $rootpath/git-libssh2
test -d build || mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$rootpath/libssh2 -DCMAKE_C_FLAGS="-ldl -lz"
cmake --build .
cmake --build . --target install

# Build libgit2
cd $rootpath/git-libgit2
test -d build || mkdir build && cd build
export OPENSSL_ROOT_DIR=$rootpath/openssl
cmake .. -DCMAKE_INSTALL_PREFIX=$rootpath/libgit2
cmake --build . --target install

exit 1

# Build QT
cd $rootpath/git-qt 
./init-repository || true
./configure -opensource -confirm-license -prefix $rootpath/qt -I $rootpath/openssl/include && make
cd $rootpath

