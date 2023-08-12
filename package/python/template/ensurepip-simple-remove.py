import importlib.metadata
import os
import os.path
import re
import sys
import sysconfig
import zipfile


if (len(sys.argv) < 2) or not sys.argv[1]:
    raise ValueError("Specify directory with wheels")

try:
    filenames = os.listdir(sys.argv[1])
except OSError:
    # Ignore: path doesn't exist or permission error
    filenames = ()
if not filenames:
    raise ValueError("Unable to find files")

filenames = sorted(filenames)
wheels = [ k for k in filenames if k.endswith(".whl") ]
if not wheels:
    raise ValueError("Unable to find wheels")

filenames = [ os.path.normpath(os.path.join(sys.argv[1], k)) for k in wheels ]

zipmark = re.compile(r'^([^/]+)/__init__\.py$')
zipfiles = []
for f in filenames:
    with zipfile.ZipFile(f) as z:
        zipfiles += [ k for k in z.namelist() if zipmark.match(k) ]

modules = []
for f in zipfiles:
    modules += [ zipmark.match(f)[1] ]
if not modules:
    raise ValueError("Unable to enumerate modules")

paths = []
for m in modules:
    try:
        d = importlib.metadata.distribution(m)
    except:
        continue
    paths += [ str(k) for k in d.files ]

purelib = sysconfig.get_paths()['purelib']
fullpaths = [ os.path.normpath(os.path.join(purelib, k)) for k in paths ]

to_remove = [ k for k in fullpaths if os.path.exists(k) ]

for k in to_remove:
    os.unlink(k)

exit(0)
