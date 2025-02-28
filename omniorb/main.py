import os, sys

def run_omniNames():
    argv = [os.path.join(os.path.dirname(__file__), "bin", "omniNames"), *sys.argv[1:]]
    if os.name == 'posix':
        os.execv(argv[0], argv)
    else:
        import subprocess; sys.exit(subprocess.call(argv))
