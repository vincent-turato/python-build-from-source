import unittest
import ssl
import blosc
import platform


class TestBuild(unittest.TestCase):
    def test_python_version(self):
        self.assertEqual(platform.python_version(), '3.5.4')
    def test_open_ssl_version(self):
        # OPENSSL_VERSION_NUMBER: The raw version number of the OpenSSL library, as a single integer:
        # open ssl 1.0.2o = 268443903
        self.assertEqual(ssl.OPENSSL_VERSION_NUMBER, 268443903)
    def test_c_blosc_version(self):
        self.assertEqual(blosc.blosclib_version.split(' ', 1)[0], '1.14.2')
    def test_python_blosc_version(self):
        self.assertEqual(blosc.__version__, '1.5.1')

if __name__ == '__main__':
    print("\nC Blosc version: " + blosc.blosclib_version)
    print(ssl.OPENSSL_VERSION)
    print("Python Blosc version: " + blosc.__version__)
    print("Python version: " + platform.python_version() + "\n")
    unittest.main()
