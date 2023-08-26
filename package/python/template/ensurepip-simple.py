import os
import os.path
import sys
import subprocess


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

for k in [k for k in os.environ if k.startswith("PIP_")]:
    del os.environ[k]
os.environ['PIP_CONFIG_FILE'] = os.devnull

args = ["install", "--no-cache-dir", "--no-index", "--no-warn-script-location", "--no-compile", *filenames ]

code = f"""
import runpy
import sys
sys.path = { filenames or [] } + sys.path
sys.argv[1:] = { args }
runpy.run_module("pip", run_name="__main__", alter_sys=True)
"""

cmd = [ sys.executable, '-W', 'ignore::DeprecationWarning', '-c', code ]

exit(subprocess.run(cmd, check=True).returncode)
