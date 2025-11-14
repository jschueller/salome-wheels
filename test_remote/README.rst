Test avec deux conteneurs debian:11 avec configuration ssh et ydefx.

Lancer le script maître::

    docker compose down && docker compose up --build

Se connecter sur le worker::

    docker-compose exec worker bash

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
- PerfTest0.xml/yacs_config.json/yacs_driver_overrides.py: test via YACS driver
  problème rencontré: le point d'entrée driver doit être créé par la wheel: corrigé dans 9.14.0.post5
