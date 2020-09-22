# ***************
# -----------------
# Instructions for downloading and building each component by hand
# 	Python 3.5.4
# 	OpenSSL 1.0.2o
# 	python-blosc 1.5.1
# 	c-blosc 1.14.2
# -----------------
# ***************

# ==================================
# 1) Install needed apt packages
# ==================================
# Assuming fresh install of Ubuntu 18.04, update/upgrade packages
sudo apt update
sudo apt upgrade -y
# Install required packages
sudo apt install -y build-essential checkinstall cmake python3-pip libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev zlib1g-dev

# Create temporary work space
originalPath=$PWD
tempWorkspace=/tmp/python-build
mkdir $tempWorkspace
cd $tempWorkspace

# ===================================
# 2) Download Python and build components
# ===================================

#	(Method A: Very Manual) Go to the GitHub releases page for each component and download the tar archive:
#	 	(Python 3.5.4) https://github.com/python/cpython/releases/tag/v3.5.4
#	 	(OpenSSL 1.0.2o) https://github.com/openssl/openssl/releases/tag/OpenSSL_1_0_2o
#	 	(python-blosc 1.5.1) https://github.com/Blosc/python-blosc/releases/tag/v1.5.1
#	 	(c-blosc 1.14.2) https://github.com/Blosc/c-blosc/releases/tag/v1.14.2
#
#		then, extract each to our temporary workspace:
#			tar -xvzf ~/Downloads/python-blosc-1.5.1.tar.gz .
#			tar -xvzf ~/Downloads/cpython-3.5.4.tar.gz .
#			tar -xvzf ~/Downloads/openssl-OpenSSL_1_0_2o.tar.gz .
#			tar -xvzf ~/Downloads/c-blosc-1.14.2.tar.gz .
#

# 	(Method B) or just curl download and untar like so:
		curl https://codeload.github.com/python/cpython/tar.gz/v3.5.4 | tar xz
		curl https://codeload.github.com/openssl/openssl/tar.gz/OpenSSL_1_0_2o | tar xz
		curl https://codeload.github.com/Blosc/c-blosc/tar.gz/v1.14.2 | tar xz
		curl https://codeload.github.com/Blosc/python-blosc/tar.gz/v1.5.1 | tar xz



# ===================================
# 3. Compile dependencies and Python
# ===================================

# ---------------------------
# 3.1) Compile OpenSSL 1.0.2o
# ---------------------------
# This will build and install OpenSSL in the default location: /usr/local/ssl.
# If you want to install it anywhere else, run config like this:
#
# $ ./config --prefix=/usr/local --openssldir=/usr/local/openssl
#
# For more info: https://github.com/openssl/openssl/blob/OpenSSL_1_0_2o/INSTALL

cd openssl-OpenSSL_1_0_2o
./config shared --prefix=/usr/local/ -fPIC
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

# You can also modify Setup.dist to extend this build process
# Either copy the included modified Setup.dist file
# to /path/to/python/Modules/Setup.dist, OR
# edit /path/to/python/Modules/Setup.dist and uncomment the following lines:
#       SSL=/usr/local
#       _ssl _ssl.c \
#               -DUSE_SSL -I$(SSL)/include -I$(SSL)/include/openssl \
#               -L$(SSL)/lib -lssl -lcrypto
cp $originalPath/Setup.dist Modules/

# For an optimized python build, pass the flag '--enable-optimizations' to the configure script
# You can customize the configuration by passing additional options to the configure script; run ./configure --help to learn more
# For more info: https://github.com/python/cpython/blob/v3.5.4/README

make distclean # cleanup any previous build
./configure --with-zlib --prefix=/usr/local/
make
make test
# use make altinstall so the primary python installation isn't overridden
sudo make altinstall

# ---------------------------
# 3.3) Install and upgrade pip, setuptools, wheel
# ---------------------------
python3.5 -m ensurepip --default-pip
python3.5 -m pip install --upgrade pip setuptools wheel


# ---------------------------
# 3.4) Compile c-blosc 1.14.2
# ---------------------------
# For more info: https://github.com/Blosc/c-blosc/blob/v1.14.2/README.md
# Create build folder for c-blosc
cd ../c-blosc-1.14.2
mkdir build
cd build

# Run CMake configuration and optionally specify the installation directory (e.g. '/usr' or '/usr/local'):
BLOSC_DIR=/usr/local
export BLOSC_DIR
cmake -DCMAKE_INSTALL_PREFIX=$BLOSC_DIR ..

# Build, test and install Blosc:
cmake --build .
ctest
cmake --build . --target install

# ---------------------------
# 3.5) Compile python-blosc
# ---------------------------
# You can tell python-blosc where the C-Blosc library with the variable we set earlier ($BLOSC_DIR)

# For more info: https://github.com/Blosc/python-blosc/blob/v1.5.1/README.rst

# Build and install python-blosc
cd ../../python-blosc-1.5.1
python3.5 setup.py build_ext --inplace
python3.5 setup.py install

# Test python-blosc
PYTHONPATH=.
export PYTHONPATH
python3.5 -m pip install numpy psutil # needed only for tests
python3.5 blosc/test.py  #add -v for verbose mode
python3.5 -m pip uninstall -y numpy psutil # return back to previous state

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


