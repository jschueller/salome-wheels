# from kernel/src/Container/Test/testProxy.py: testAccessOfResourcesAcrossWorkers

import os
import pickle
import tempfile

from salome.kernel import salome
from salome.kernel import Engines
from salome.kernel import pylauncher
from salome.kernel import KernelBasis

# global parameters
# KernelBasis.SetPyExecutionMode("OutOfProcessNoReplay")
salome.standalone()
salome.salome_init()
salome.cm.SetDirectoryForReplayFiles("/tmp")

### start of catalog manipulation in memory
rmcpp = pylauncher.RetrieveRMCppSingleton()
cpy = {elt:rmcpp[elt] for elt in rmcpp.GetListOfEntries()}
remote_applipath = cpy["localhost"].applipath  # assume same applipath as installed with wheels too
for i in range(2):
    res = pylauncher.CreateContainerResource(f"cresource{i}", remote_applipath, "ssh")
    res.nb_node = 2
    res.hostname = "worker"  # default hostname=cresource{i}
    rmcpp.AddResourceInCatalogNoQuestion(res)
### end of catalog manipulation in memory

### start to check effectivity of manipulation locally
machines = salome.rm.ListAllResourceEntriesInCatalog()
localStructure = { machine : salome.rm.GetResourceDefinition2( machine ) for machine in machines }
print("localStructure=", localStructure)
### end of check effectivity of manipulation locally

cp = pylauncher.GetRequestForGiveContainer("cresource0", "gg")
with salome.ContainerLauncherCM(cp) as cont:
    pyscript = cont.createPyScriptNode("testScript","""
from salome.kernel import salome
import socket

salome.salome_init()
machines = salome.rm.ListAllResourceEntriesInCatalog()
structure = { machine : salome.rm.GetResourceDefinition2( machine ) for machine in machines }
assert socket.gethostname() == 'worker', socket.gethostname()
""") # retrieve the content remotely and then return it back to current process
    from salome.kernel import SALOME_PyNode
    import pickle
    poa = salome.orb.resolve_initial_references("RootPOA")
    obj = SALOME_PyNode.SenderByte_i(poa,pickle.dumps( ([],{}) ))
    id_o = poa.activate_object(obj)
    refPtr = poa.id_to_reference(id_o)
    #
    pyscript.executeFirst(refPtr)
    ret = pyscript.executeSecond(["structure"])
    ret = ret[0]
    retPy = pickle.loads(SALOME_PyNode.SeqByteReceiver(ret).data())

    assert len(localStructure) == len(retPy)
    assert "cresource0" in localStructure
    assert localStructure["cresource0"].applipath == remote_applipath
    assert "cresource1" in localStructure
    assert localStructure["cresource1"].applipath == remote_applipath
    for k in localStructure:
        a = pylauncher.FromEngineResourceDefinitionToCPP( localStructure[k] )
        assert isinstance(a,pylauncher.ResourceDefinition_cpp)
        b = pylauncher.FromEngineResourceDefinitionToCPP( retPy[k] )
        assert isinstance(b,pylauncher.ResourceDefinition_cpp)
        assert a==b  #<- key point is here
        a1 = pylauncher.ToEngineResourceDefinitionFromCPP( a )
        b1 = pylauncher.ToEngineResourceDefinitionFromCPP( b )
        a2 = pylauncher.FromEngineResourceDefinitionToCPP( a1 )
        b2 = pylauncher.FromEngineResourceDefinitionToCPP( b1 )
        assert a2==b2
        print("ok")
