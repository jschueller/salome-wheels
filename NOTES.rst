- omniorb: ok, attention à bien combiner les modules binaires issus des deux paquets omniorb et omniorbpy
- libbatch: ok, remplacement de PYTHON_LIBRARIES par une string vide pour ne pas lier les modules swig à libpython (linux seulement)
  une alternative serait d'utiliser le module cmake FindPython qui permet de lier les modules à la façon PyPA::

    cmake_minimum_required (VERSION 3.18)
    find_package (Python 3 COMPONENTS Interpreter Development.Module)
    # PYTHON_EXECUTABLE devient Python_Executable
    # PYTHON_LIBRARIES devient Python::Module (modules seulement)
    target_link_libraries(libbatch Python::Module)

  mais il faudrait le propager dans tous les modules Salome.
  Dans l'état actuel on utilise des surcouches (CMakeModules/FindLibbatchPython.cmake pour libbatch)
  ou configuration/cmake/FindSalomePythonLibs.cmake/FindSalomePythonInterp.cmake ailleurs)
  qui vérifient la cohérence entre l'interpreteur et les bibliothèques qui étaient détectés séparement
  par les modules FindPythonInterp/FindPythonLibs qui sont maintenant obsolètes.

- kernel: 

  1. Les executables SALOME_Container et co utilisent des symboles Python, on est donc obligés de lier explicitement à Python
     au moins pour ces binaires là, ici on recompile une version statique de Python.
     En contrepartie il faut aussi lier à libutil pour les symboles forkpty/openpty
     
  2. Attention les modules Salome dont kernel installent des modules swig dans /lib/salome et des sous-répertoires /lib/python3.x/site-packages/salome
     Pour les wheels on ne peut installer que dans un seul endroit car l'archive de la wheel sera decompressée dans /lib/python3.x/site-packages
     et on ne pourra donc pas installer dans /lib ou un autre chemin parent de /site-packages
     On ne peut pas non plus présupposer que le PYTHONPATH sera positionné
     (ie ni à /lib/salome ni à auncun sous-répertoire de /lib/python3.x/site-packages)
     comme ce qui est fait dans l'archive binaire de Salome via le script env_launch.sh::

       export PYTHON_LIBDIR="lib/python${PYTHON_VERSION}/site-packages"
       ...
       export PYTHONPATH="${KERNEL_ROOT_DIR}/${PYTHON_LIBDIR}/salome:${PYTHONPATH}"
       
     Par exemple le module kernel installe tout dans SALOME_INSTALL_PYTHON ou INSTALL_PYIDL_DIR qui valent /lib/python3.x/site-packages/salome
     INSTALL_PYIDL_DIR est définit dans configuration/cmake/UseOmniORB.cmake.
     On veut donc éviter ce premier répertoire racine salome sinon kernel s'importerait via salome.salome.kernel
     On voudra changer le type de SALOME_INSTALL_PYTHON de PATH à STRING pour qu'il reste relatif lorsque surchargé en ligne de commande.
     Modifier SALOME_INSTALL_PYTHON et INSTALL_PYIDL_DIR résulte en ce que salome.kernel ne soit pas installé: on peut déplacer le dossier manuellement
     sys.path.append(os.path.dirname(__file__))
     

  3. Il y a aussi un module "salome" espace de nom (cf variable __package__) qui contient tous les sous-modules (eg salome.kernel)
     qui par défaut est donc installé dans /lib/python3.x/site-packages/salome/salome
     Le fichier src/KERNEL_PY/__init__.py explique son fonctionnement

  4. La variable d'environement KERNEL_ROOT_DIR est utilisée pour donner le chemin vers les catalogues xml.
     Pour la wheel on peut copier tout dce qui est installé dans /share vers le repertoire racine de la wheel
     et positionner KERNEL_ROOT_DIR depuis le fichier racine salome/__init__.py
