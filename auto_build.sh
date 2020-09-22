# Automated build script for:
#	Python 3.5.4
# 	OpenSSL 1.0.2o
# 	python-blosc 1.5.1
# 	c-blosc 1.14.2

# Instructions
# 	1) Run this file via sudo ./auto_build.sh

# To extend this script for other extensions:
# 	1) Add any required apt packages for extension in Step 1
#	2) Add download/extract code for extension to Step 2
#	3) Add its build and test commands to Step 3
#	4) Add unit tests for new extension to tests.py file

# ===================================
# 1) Install needed apt packages
# ===================================
# Assuming fresh install of Ubuntu 18.04, update/upgrade packages
sudo apt update
sudo apt upgrade -y

# Install required packages
sudo apt install -y build-essential checkinstall cmake python3-pip libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev zlib1g-dev

# ===================================
# 2) Download Python and build components
# ===================================

# Create temporary work space
originalPath=$PWD
tempWorkspace=/tmp/python-build
mkdir $tempWorkspace
cd $tempWorkspace

# Python 3.5.4:
curl https://codeload.github.com/python/cpython/tar.gz/v3.5.4 | tar xz
# OpenSSL 1.0.2o:
curl https://codeload.github.com/openssl/openssl/tar.gz/OpenSSL_1_0_2o | tar xz
# c-blosc 1.14.2:
curl https://codeload.github.com/Blosc/c-blosc/tar.gz/v1.14.2 | tar xz
# python-blosc 1.5.1:
curl https://codeload.github.com/Blosc/python-blosc/tar.gz/v1.5.1 | tar xz

# ===================================
# 3. Compile dependencies and Python
# ===================================

# ---------------------------
# 3.1) Compile OpenSSL 1.0.2o
# ---------------------------
# This will build and install OpenSSL in the default location, which is (for historical reasons) /usr/local/ssl.
# If you want to install it anywhere else, run config like this:

# $ ./config --prefix=/usr/local --openssldir=/usr/local/openssl

# For more info: https://github.com/openssl/openssl/blob/OpenSSL_1_0_2o/INSTALL

cd openssl-OpenSSL_1_0_2o
./config shared --prefix=/usr/local/
make
make test
make install

# ---------------------------
# 3.2) Compile Python
# ---------------------------
# To specify Python install location:
# ./configure --prefix=/path/to/custom/python/
cd ../cpython-3.5.4

# Specify environment variables for OpenSSL shared library
export LDFLAGS="-L/usr/local/lib/ $LDFLAGS"
export LD_LIBRARY_PATH="/usr/local/lib/:/usr/local/:$LD_LIBRARY_PATH"
export CPPFLAGS="-I/usr/local/include -I/usr/local/include/openssl $CPPFLAGS"

# Either copy the included modified Setup.dist file
# to /path/to/python/Modules/Setup.dist, OR
# edit /path/to/python/Modules/Setup.dist and uncomment the following lines:
# 	SSL=/usr/local
# 	_ssl _ssl.c \
#		-DUSE_SSL -I$(SSL)/include -I$(SSL)/include/openssl \
#		-L$(SSL)/lib -lssl -lcrypto
cp $originalPath/Setup.dist Modules/

./configure --with-zlib --prefix=/usr/local/
make
make test
sudo make altinstall # use altinstall so we don't overwrite primary Python

# ---------------------------
# 3.3) Install and upgrade pip, setuptools, wheel
# ---------------------------
python3.5 -m ensurepip --default-pip
python3.5 -m pip install --upgrade pip setuptools wheel

# ---------------------------
# 3.4) Compile c-blosc 1.14.2
# ---------------------------
cd ../c-blosc-1.14.2
mkdir build
cd build

# Run CMake configuration and optionally specify the installation directory (e.g. '/usr' or '/usr/local'):
BLOSC_DIR=/usr/local
export BLOSC_DIR
cmake -DCMAKE_INSTALL_PREFIX=$BLOSC_DIR ..
cmake --build .
ctest
cmake --build . --target install

# ---------------------------
# 3.5) Compile python-blosc
# ---------------------------
# Build and install python-blosc
cd ../../python-blosc-1.5.1
python3.5 setup.py build_ext --inplace
python3.5 setup.py install

# Test python-blosc
PYTHONPATH=.
export PYTHONPATH
python3.5 -m pip install numpy psutil # needed only for tests
python3.5 blosc/test.py  #for notes: (add -v for verbose mode)
python3.5 -m pip uninstall -y numpy psutil

# ===================================
# 4) Create needed links and cache to newly created shared libraries
# ===================================
# Run the following command in your terminal
sudo ldconfig

# ===================================
# 5) Run build tests.
# ===================================
cd ..
python3.5 $originalPath/tests.py -v
