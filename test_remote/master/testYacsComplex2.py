# from: yacs/src/yacsloader_swig/Test/testYacsPerfTest0.py: test0

import unittest
import tempfile
import os
import multiprocessing as mp
import openturns as ot

from salome.kernel import KernelBasis
from salome.kernel import salome
from salome.kernel import pylauncher
from salome.yacs import pilot
from salome.yacs import SALOMERuntime
from salome.yacs import loader

# global parameters
NB_OF_PARALLEL_NODES = 20
KernelBasis.SetPyExecutionMode('OutOfProcessNoReplay')
salome.salome_init()
salome.cm.SetDirectoryForReplayFiles("/tmp")
salome.cm.SetNumberOfRetry(1)

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
rmcpp.WriteInXmlFile("EffectiveCatalog.xml")

SALOMERuntime.RuntimeSALOME.setRuntime()
r=SALOMERuntime.getSALOMERuntime()
p=r.createProc("PerfTest0")
p.setProperty("executor","workloadmanager") # important line here to avoid that gg container treat several tasks in //.
ti=p.createType("int","int")
td=p.createType("double","double")
tdd=p.createSequenceTc("seqdouble","seqdouble",td)
tddd=p.createSequenceTc("seqseqdouble","seqseqdouble",tdd)
tdddd=p.createSequenceTc("seqseqseqdouble","seqseqseqdouble",tddd)
pyobj=p.createInterfaceTc("python:obj:1.0","pyobj",[])
seqpyobj=p.createSequenceTc("list[pyobj]","list[pyobj]",pyobj)
cont=p.createContainer("gg","Salome")
cont.setProperty("nb_parallel_procs","1")
cont.setAttachOnCloningStatus(True)
cont.setProperty("attached_on_cloning","1")
cont.setProperty("type","multi")
cont.setProperty("container_name","gg")
######## Level 0
startNode = r.createScriptNode("Salome","start")
startNode.setExecutionMode("local")
startNode.setScript("""o2 = list(range({}))""".format(NB_OF_PARALLEL_NODES))
po2 = startNode.edAddOutputPort("o2",seqpyobj)
p.edAddChild(startNode)
#
fe = r.createForEachLoopDyn("fe",pyobj)
p.edAddChild(fe)
p.edAddCFLink(startNode,fe)
p.edAddLink(po2,fe.edGetSeqOfSamplesPort())
internalNode = r.createScriptNode("Salome","internalNode")
internalNode.setExecutionMode("remote")
internalNode.setContainer(cont)
internalNode.setScript("""from salome.kernel import KernelBasis
import socket
import openturns as ot

assert socket.gethostname() == 'worker', socket.gethostname()
KernelBasis.HeatMarcel(2,1)
ret = 3*ppp
ret2 = ot.Point([3*ppp])
""")
fe.edSetNode(internalNode)
ix = internalNode.edAddInputPort("ppp",pyobj)
oret = internalNode.edAddOutputPort("ret",pyobj)
oret2 = internalNode.edAddOutputPort("ret2",pyobj)
p.edAddLink( fe.edGetSamplePort(), ix )
#
endNode = r.createScriptNode("Salome","end")
endNode.setExecutionMode("local")
endNode.setContainer(None)
ozeret = endNode.edAddOutputPort("ozeret",seqpyobj)
izeret = endNode.edAddInputPort("izeret",seqpyobj)
ozeret2 = endNode.edAddOutputPort("ozeret2", seqpyobj)
izeret2 = endNode.edAddInputPort("izeret2", seqpyobj)
endNode.setScript("""ozeret = izeret; ozeret2 = izeret2""")
p.edAddChild(endNode)
p.edAddCFLink(fe,endNode)
p.edAddLink( oret, izeret )
p.edAddLink(oret2, izeret2)
if True:
    fname = "PerfTest0.xml"
    p.saveSchema(fname)
    
    from salome.yacs import loader
    l=loader.YACSLoader()
    p=l.load(fname)
print("Start computation")
import datetime
st = datetime.datetime.now()
ex=pilot.ExecutorSwig()
ex.RunW(p,0)
assert(p.getState() == pilot.DONE)
salome.cm.ShutdownContainers()
print("End of computation {}".format( str(datetime.datetime.now()-st) ) )
if p.getChildByName("end").getOutputPort("ozeret").getPyObj() != [3*i for i in range(NB_OF_PARALLEL_NODES)]:
    raise RuntimeError("Ooops")
result2 = p.getChildByName("end").getOutputPort("ozeret2").getPyObj()
print(result2)
assert result2 == [ot.Point([3*i]) for i in range(NB_OF_PARALLEL_NODES)], "!ndarray"
