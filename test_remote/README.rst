Test avec deux conteneurs Debian (master/worker) avec configuration ssh et ydefx.

Lancer le script maître::

    docker compose down && docker compose up --build

Se connecter sur le worker (le serveur ssh tourne indéfiniment)::

    docker-compose exec worker bash

Se connecter sur le master (ajouter une commande sleep pour éviter qu'il ne soit arrêté)::

    docker-compose exec master bash

On peut paramétrer la façon dont les processus sont lancés (mode indestructible)::

    KernelBasis.SetPyExecutionMode('OutOfProcessNoReplay')

Paramétrer la verbosité::

    KernelBasis.SetVerbosityActivated(True)

Fichiers de test (dossier master):

- testProxy.py: test via KERNEL d'un échange du catalogue de resources + nom de l'hôte
  problème rencontré avec les imports (salome_utils, salomeContextUtils) corrigé dans 9.14.0.post4
- testYacs.py: test via YACS sur un DOE de 100 points avec execution de HeatMarcel
  problème rencontré sur le dossier temporaire choisi sur le master avec SetDirectoryForReplayFiles
  mais qui n'existait pas sur le worker
- testYacsComplex.py: test via YACS sur un DOE de 100 points avec execution de HeatMarcel + echange d'un ndarray numpy
- PerfTest0.xml/yacs_config.json/yacs_driver_overrides.py: test via YACS driver
  problème rencontré: le point d'entrée driver doit être créé par la wheel: corrigé dans 9.14.0.post5
- testYdefx.py: test via YDEFX sur un DOE de 100 points avec execution de HeatMarcel

Remarques:

- backport de correctifs d'imports de salome.kernel (salome_utils, salomeContextUtils)
- on spécifie le champs applipath du remote en dur à partir de celui du localhost
  (on suppose the le noeud distant utilise lui aussi les wheels installées à un emplacement identique)
- les points d'entrée utilisés pour le shell de kernel et du driver yacs constituent peut-être
  une logique différente de ce qui est prévu dans salome à base de fichier .py d'environnement cumulés
