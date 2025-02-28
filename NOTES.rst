Packaging Python de SALOME
--------------------------

- omniorb:

  1. Il faut veiller à combiner les modules Python binaires issus des deux paquets source omniorb et omniorbpy.

  2. Suivant les instructions d'EDF il faut patcher suivant le fichier omniorb-noinitfile.patch.

  3. Il faut ajouter un point d'entrée (via le fichier entry_points.txt) vers l'executable binaire omniNames
     que l'on aura inclus dans le dossier omniORB/bin de la wheel (le serveur de noms est requis par le module kernel)

- libbatch:

  1. On supprime l'unique référence PYTHON_LIBRARIES pour ne pas lier le module swig à libpython
     la façon propre serait d'utiliser le module cmake FindPython qui permet de lier les modules à la façon PyPA::

         cmake_minimum_required (VERSION 3.18)
         find_package (Python 3 COMPONENTS Interpreter Development.Module Development.Embed)
         # PYTHON_EXECUTABLE devient Python_Executable
         # PYTHON_LIBRARIES devient Python::Module pour les modules SWIG et Python::Python pour les autres cibles
         target_link_libraries(libbatch Python::Module)

     mais il faudrait le propager dans tous les modules Salome.
     Dans l'état actuel Salome utilise des surcouches (CMakeModules/FindLibbatchPython.cmake pour libbatch)
     ou configuration/cmake/FindSalomePythonLibs.cmake/FindSalomePythonInterp.cmake ailleurs)
     qui vérifient la cohérence entre l'interpreteur et les bibliothèques qui étaient détectés séparement
     par les modules FindPythonInterp/FindPythonLibs et qui sont maintenant obsolètes.

- kernel: 

  1. Sous Linux les modules Python binaires ne doivent pas être liés explicitement à la libpython: https://peps.python.org/pep-0513/#libpythonx-y-so-1on
     On enlevera les références à PYTHON_LIBRARIES dans l'infrastructure cmake pour ces cibles uniquement.

  2. Les executables SALOME_Container et co utilisent des symboles Python, on est donc obligés de lier explicitement à libpython
     au moins pour ces binaires là, et pour cela on recompile une version statique de Python.
     En conséquence il faut aussi explicitement lier à la dépendance de Python libutil pour les symboles forkpty/openpty.

  3. La variable d'environnement KERNEL_ROOT_DIR est utilisée pour donner le chemin vers les catalogues xml.
     Pour la wheel on peut copier tout ce qui est installé dans /share vers le repertoire racine de la wheel
     et positionner KERNEL_ROOT_DIR depuis le fichier kernel/__init__.py

  4. Idem pour PATH qui doit être mis à jour pour utiliser bin/salome après avoir copié le répertoire d'installation /bin dans salome/kernel.

  5. ABSOLUTE_APPLI_PATH pointe aussi vers la racine du sous-module salome/kernel, nécessaire pour les tests
     Cependant la command test ne trouve pas les fichiers de tests qui sont installés dans le sous-répertoire kernel, cf fichier source bin/runTests.py::
     
        # tests must be in ${ABSOLUTE_APPLI_PATH}/${__testSubDir}/
        -__testSubDir = "bin/salome/test"
        +__testSubDir = "bin/salome/test/kernel"

  6. ldd crashe sur certains executables, il semblerait que la commande patchelf --remove-rpath emise par auditwheel les corrompt;
     une solution est de patcher localement auditwheel pour supprimer cette commande

  7. Le chemin relatif de ScriptsTemplate renvoyé par getDftLocOfScripts doit adapté relativement à KernelContainer.py

  8. Un executable factice est lié à la bibliothèque with_loggerTraceCollector chargée dynamiquement afin que celle-ci soit inclue
     dans le dossier salome.kernel.libs par auditwheel, il faut aussi faire une copie de la version renommée pour garder le nom original

  9. Les variables d'environnement HOME et USER sont obligatoires, sinon salome_init plante; on suggère de tester la présence de ces variables.

  10. Il faut ajouter un point d'entrée (via le fichier entry_points.txt) vers l'executable (Python) salome utilisé pour `salome shell` par exemple.

  Les patches nécessaires sont disponibles dans la branche https://github.com/jschueller/kernel/tree/jsr/43708_pip_exp basée sur agy/43708_pip_exp.

- yacs:

  1. Idem on évite de lier les modules SWIG à libpython (ne pas appliquer car cela ne fonctionnera pas sous mac/windows).
     
  2. Idem que pour kernel: on positionne YACS_ROOT_DIR, PATH depuis yacs/__init__.py

  3. on modifie encore la variable __testSubDir de salome/kernel/runTests.py pour pointer vers le sous-dossier yacs sinon les test ne sous pas trouvés
  
  4. Le fichier PMML.py doit être installé dans SALOME_YACS_INSTALL_PYTHON au lieu de SALOME_INSTALL_SCRIPT_PYTHON, cf src/pmml/pmml_swig/CMakeLists.txt
     Les imports sont changés en import salome.yacs.PMML

  5. Des fichiers xml sont nécessaires à l'execution de tests et doivent etre copiés depuis share/yacssamples vers salome/bin/salome/test/yacs/yacsloader_swig/samples
  
  Les patches nécessaires sont disponibles dans la branche https://github.com/jschueller/yacs/tree/jsr/43708_pip basée sur agy/43708_pip.

  6. Les tests suivants peuvent échouer de manière non reproductible suivant les réplications de la construction des binaires kernel et yacs::

      The following tests FAILED:
          7 - YACS_basic_first_SSL (Failed)                     YACS
         12 - YACS_PyNodeWithCache_swig (Failed)                YACS
         13 - YACS_WorkloadManager_swig (Failed)                YACS
         17 - YACS_SaveLoadRun_swig (Failed)                    YACS
         18 - YACS_ProxyTest_swig (Failed)                      YACS
         19 - YACS_PerfTest0_swig (Failed)                      YACS
         20 - YACS_Driver_Overrides (Failed)                    YACS
         22 - YACS_Fixes_swig (Failed)                          YACS
         24 - YACS_PyDecorator (Failed)                         YACS

     Le test YACS_PyNodeWithCache_swig est charactéristique.

- py2cpp

  1. Idem on évite de lier les modules SWIG à libpython (ne pas appliquer car cela ne fonctionnera pas sous mac/windows).
     Il faut ajouter le lien à libdl puisqu'on linke quand même l'executable de test à une version statique.

- ydefx:

  1. Module pur-python, on ne lance pas les tests C++ car libydefx.so n'est pas empaquetée (car pas requise par un module SWIG)

  2. Le module est nommé pydefx au lieu de salome.pydefx au vu des imports même s'il est installé dans salome/pydefx
     Il contient aussi le module mpmcn.py

  3. On exclut les tests c++ YDEFX_StudyGeneralTest/YDEFX_StudyRestartTest/YDEFX_SampleTest qui nécessitent libydefx.so
