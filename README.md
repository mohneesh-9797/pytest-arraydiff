[![Travis Build Status](https://travis-ci.org/astrofrog/pytest-arraydiff.svg?branch=master)](https://travis-ci.org/astrofrog/pytest-arraydiff)
[![AppVeyor Build status](https://ci.appveyor.com/api/projects/status/kwbvm9u79mrq6i0w?svg=true)](https://ci.appveyor.com/project/astrofrog/pytest-arraydiff)

About
-----

This is a [py.test](http://pytest.org) plugin to facilitate the generation and
comparison of arrays produced during tests (this is a spin-off from
[pytest-arraydiff](https://github.com/astrofrog/pytest-arraydiff)).

The basic idea is that you can write a test that generates a Numpy array. You
can then either run the tests in a mode to **generate** reference files from the
arrays, or you can run the tests in **comparison** mode, which will compare the
results of the tests to the reference ones within some tolerance.

At the moment, the supported file formats for the reference files are:

* The FITS format (requires [astropy](http://www.astropy.org))
* A plain text-based format (baed on Numpy ``loadtxt`` output)

For more information on how to write tests to do this, see the **Using**
section below.

Installing
----------

This plugin is compatible with Python 2.7, and 3.3 and later, and requires
[pytest](http://pytest.org) and [numpy](http://www.numpy.org) to be installed.

To install, you can do:

    pip install https://github.com/astrofrog/pytest-arraydiff/archive/master.zip

You can check that the plugin is registered with pytest by doing:

    py.test --version

which will show a list of plugins:

    This is pytest version 2.7.1, imported from ...
    setuptools registered plugins:
      pytest-arraydiff-0.1 at ...

Using
-----

To use, you simply need to mark the function where you want to compare images
using ``@pytest.mark.array_compare``, and make sure that the function
returns a plain Numpy array::

    python
    import pytest
    import numpy as np

    @pytest.mark.array_compare
    def test_succeeds():
        return np.arange(3 * 5 * 4).reshape((3, 5, 4))

To generate the reference FITS files, run the tests with the
``--arraydiff-generate-path`` option with the name of the directory where the
generated files should be placed:

    py.test --arraydiff-generate-path=reference

If the directory does not exist, it will be created. The directory will be
interpreted as being relative to where you are running ``py.test``. Make sure
you manually check the reference images to ensure they are correct.

Once you are happy with the generated FITS files, you should move them to a
sub-directory called ``reference`` relative to the test files (this name is
configurable, see below). You can also generate the baseline images directly
in the right directory.

You can then run the tests simply with:

    py.test --arraydiff

and the tests will pass if the images are the same. If you omit the
``--arraydiff`` option, the tests will run but will only check that the code
runs without checking the output images.

Options
-------

The ``@pytest.mark.array_compare`` marker take an argument to specify the format
to use for the reference files:

```python
@pytest.mark.array_compare(file_format='text')
def test_image():
    ...
```

The default file format can also be specified using the
``--arraydiff-default-format=<format>`` flag when running ``py.test``, and
``<format>`` should be either ``fits`` or ``text``.

The supported formats at this time are ``text`` and ``fits``, and contributions
for other formats are welcome. The default format is ``text``.

Another argument is the relative tolerance for floating point values (which
defaults to 1e-7):

```python
@pytest.mark.array_compare(rtol=20)
def test_image():
    ...
```

You can also pass keyword arguments to the writers using the ``write_kwargs``.
For the ``text`` format, these arguments are passed to ``savetxt`` while for
the ``fits`` format they are passed to Astropy's ``fits.writeto`` function.

```python
@pytest.mark.array_compare(file_format='fits', write_kwargs={'output_verify': 'silentfix'})
def test_image():
    ...
```

Other options include the name of the reference directory (which defaults to
``reference`` ) and the filename for the reference file (which defaults to the
name of the test with a format-dependent extension).

```python
@pytest.mark.array_compare(reference_dir='baseline_images',
                               filename='other_name.fits')
def test_image():
    ...
```

The reference directory in the decorator above will be interpreted as being
relative to the test file. Note that the baseline directory can also be a
URL (which should start with ``http://`` or ``https://`` and end in a slash).

Finally, you can also set a custom baseline directory globally when running
tests by running ``py.test`` with:

    py.test --arraydiff --arraydiff-reference-path=baseline_images

This directory will be interpreted as being relative to where the tests are
run. In addition, if both this option and the ``reference_dir`` option in the
``array_compare`` decorator are used, the one in the decorator takes
precedence.

Test failure example
--------------------

If the images produced by the tests are correct, then the test will pass, but if they are not, the test will fail with a message similar to the following:

```
E               AssertionError:
E               
E               a: /var/folders/zy/t1l3sx310d3d6p0kyxqzlrnr0000gr/T/tmpbvjkzt_q/test_to_mask_rect-mode_subpixels-subpixels_18.txt
E               b: /var/folders/zy/t1l3sx310d3d6p0kyxqzlrnr0000gr/T/tmpbvjkzt_q/reference-test_to_mask_rect-mode_subpixels-subpixels_18.txt
E               
E               Not equal to tolerance rtol=1e-07, atol=0
E               
E               (mismatch 47.22222222222222%)
E                x: array([[ 0.      ,  0.      ,  0.      ,  0.      ,  0.404012,  0.55    ,
E                        0.023765,  0.      ,  0.      ],
E                      [ 0.      ,  0.      ,  0.      ,  0.112037,  1.028704,  1.1     ,...
E                y: array([[ 0.      ,  0.      ,  0.      ,  0.      ,  0.367284,  0.5     ,
E                        0.021605,  0.      ,  0.      ],
E                      [ 0.      ,  0.      ,  0.      ,  0.101852,  0.935185,  1.      ,...
```

The file paths included in the exception are then available for inspection.

Running the tests for pytest-arraydiff
--------------------------------------

If you are contributing some changes and want to run the tests, first install
the latest version of the plugin then do:

    cd tests
    py.test --arraydiff

The reason for having to install the plugin first is to ensure that the plugin
is correctly loaded as part of the test suite.
