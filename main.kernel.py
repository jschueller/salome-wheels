import os, sys

def run_salome():
    argv = [sys.executable, os.path.join(os.path.dirname(__file__), "..", "bin", "salome", "appli", "salome"), *sys.argv[1:]]
    if os.name == 'posix':
        os.execv(argv[0], argv)
    else:
        import subprocess; sys.exit(subprocess.call(argv))
