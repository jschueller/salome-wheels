
## driver --options_from_json=yacs_config.json  --activate-custom-overrides PerfTest0.xml

import multiprocessing as mp

from salome.kernel import KernelBasis
from salome.kernel import pylauncher


def manipulateResourceList():
    # import multiprocessing as mp
    # rmcpp = pylauncher.RetrieveRMCppSingleton()
    # cpy = {elt:rmcpp[elt] for elt in rmcpp.GetListOfEntries()}
    # rmcpp.DeleteAllResourcesInCatalog()
    # localhost = cpy["localhost"]
    # localhost.nb_node = mp.cpu_count() // 2
    # #localhost.applipath = "/loc/appli"
    # rmcpp.AddResourceInCatalogNoQuestion(localhost)
    
    # resources
    rmcpp = pylauncher.RetrieveRMCppSingleton()
    cpy = {elt:rmcpp[elt] for elt in rmcpp.GetListOfEntries()}
    rmcpp.DeleteAllResourcesInCatalog()
    remote_applipath = cpy["localhost"].applipath  # assume same applipath as installed with wheels too
    for i in range(1):
        res = pylauncher.CreateContainerResource(f"cresource{i}", remote_applipath, "ssh")
        res.nb_node = mp.cpu_count() // 4
        res.hostname = "worker"  # default hostname=cresource{i}
        rmcpp.AddResourceInCatalogNoQuestion(res)
    # rmcpp.WriteInXmlFile("EffectiveCatalog.xml")

def prepareTMPDirectory( cm ):
    from pathlib import Path
    p = Path("/tmp").absolute()
    if not p.is_dir():
        p.mkdir()
    print( f"Tmp directory to exchange pickles during evaluation : \"{p}\"" )

    cm.SetDirectoryForReplayFiles( str( p ) )
    KernelBasis.SetPyExecutionMode('OutOfProcessNoReplay')


########## le point d'entrée est ici pour yacs ######
def customize(cm, allresources):
    #verbosity steering
    #KernelBasis.SetVerbosityActivated(True)
    #KernelBasis.SetVerbosityLevel( "DEBUG" )
    #
    prepareTMPDirectory( cm )
    cm.SetNumberOfRetry( 1 )
    cm.SetCodeOnContainerStartUp( "import os" )
    cm.SetOverrideEnvForContainersSimple([("PHIMECA","/home/julien")])
    manipulateResourceList()
