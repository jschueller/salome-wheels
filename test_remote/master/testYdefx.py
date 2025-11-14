import pydefx
import multiprocessing as mp

# parameters
from salome.kernel import pylauncher
rmcpp = pylauncher.RetrieveRMCppSingleton()
cpy = {elt:rmcpp[elt] for elt in rmcpp.GetListOfEntries()}
remote_applipath = cpy["localhost"].applipath  # assume same applipath as installed with wheels too
for i in range(1):
    res = pylauncher.CreateContainerResource(f"cresource{i}", remote_applipath, "ssh")
    res.nb_node = mp.cpu_count() // 4
    res.hostname = "worker"  # default hostname=cresource{i}
    rmcpp.AddResourceInCatalogNoQuestion(res)
params = pydefx.Parameters("cresource0", 4)
params.createResultDirectory("/tmp")
params.salome_parameters.in_files = []

# code
study = pydefx.PyStudy()
run_script = pydefx.PyScript()
run_script.loadString(f"""
from salome.kernel import KernelBasis
import socket

def _exec(ppp):
    KernelBasis.HeatMarcel(2,1)
    ret = 3*ppp
    assert socket.gethostname() == 'worker', socket.gethostname()
    return ret
""")
print("entrées:", run_script.getInputNames())
print("sorties:", run_script.getOutputNames())

# design
ydefx_sample = run_script.CreateEmptySample()
NB_OF_PARALLEL_NODES = 100
dict_sample = {"ppp": list(range(NB_OF_PARALLEL_NODES))}
ydefx_sample.setInputValues(dict_sample)
study.createNewJob(run_script, ydefx_sample, params)
study.launch()
study.wait()
result = study.getResult()
print("exit=", result.getExitCode())
print("haserror=", result.hasErrors())
if result.hasErrors():
    print(result.getErrors())
    print(study.sample.getMessages())
    raise RuntimeError("Could not evaluate sample using pydefx backend")
inv = study.sample.getInput("ppp")
print(inv)
outv = study.sample.getOutput("ret")
print(outv)
assert outv == [3*i for i in range(NB_OF_PARALLEL_NODES)]
