using Revise
using Neo4j # So that DFG initializes the database driver.
using RoME
using DistributedFactorGraphs
using Test, Dates

# start with an empty factor graph object
# fg = initfg()
cloudFg = CloudGraphsDFG{SolverParams}("localhost", 7474, "neo4j", "test",
    "testUser", "testRobot", "testSession",
    nothing,
    nothing,
    IncrementalInference.decodePackedType,
    IncrementalInference.rebuildFactorMetadata!,
    solverParams=SolverParams())
# cloudFg = GraphsDFG{SolverParams}(params=SolverParams())
# cloudFg = GraphsDFG{SolverParams}(params=SolverParams())
clearSession!!(cloudFg)
# cloudFg = initfg()

# Add the first pose :x0
x0 = addVariable!(cloudFg, :x0, Pose2)
IncrementalInference.compareVariable(x0, getVariable(cloudFg, :x0))

# Add at a fixed location PriorPose2 to pin :x0 to a starting location (10,10, pi/4)
prior = addFactor!(cloudFg, [:x0], PriorPose2( MvNormal([10; 10; 1.0/8.0], Matrix(Diagonal([0.1;0.1;0.05].^2))) ) )

# Drive around in a hexagon in the cloud
for i in 0:5
    psym = Symbol("x$i")
    nsym = Symbol("x$(i+1)")
    addVariable!(cloudFg, nsym, Pose2)
    pp = Pose2Pose2(MvNormal([10.0;0;pi/3], Matrix(Diagonal([0.1;0.1;0.1].^2))))
    addFactor!(cloudFg, [psym;nsym], pp )
end

# Right, let's copy it into local memory for solving...
localFg = GraphsDFG{SolverParams}(params=SolverParams())
DistributedFactorGraphs._copyIntoGraph!(cloudFg, localFg, union(getVariableIds(cloudFg), getFactorIds(cloudFg)), true)
# Some checks
@test symdiff(getVariableIds(localFg), getVariableIds(cloudFg)) == []
@test symdiff(getFactorIds(localFg), getFactorIds(cloudFg)) == []
@test isFullyConnected(localFg)
# Show it
toDotFile(localFg, "/tmp/localfg.dot")

# Alrighty! At this point, we should be able to solve locally...
# perform inference, and remember first runs are slower owing to Julia's just-in-time compiling
# Can do with graph too!
# tree, smt, hist = solveTree!(localFg)

# wipeBuildNewTree!(localFg)
tree, smt, hist = solveTree!(localFg, tree) # Recycle
# batchSolve!(localFg, drawpdf=true, show=true)
# Erm, whut? Error = mcmcIterationIDs -- unaccounted variables

# Trying new method.
# tree, smtasks = batchSolve!(localFg, treeinit=true, drawpdf=true, show=true,
                            # returntasks=true, limititers=50,
                            # upsolve=true, downsolve=true  )

# Testing writing estimates
for variable in getVariables(localFg)
    means = mean(getData(variable).val, dims=2)[:]
    variable.estimateDict[:default] = Dict{Symbol, VariableEstimate}(:Mean => VariableEstimate(:default, :Mean, means, now()))
end

x0 = getVariable(localFg, :x0)
data = getData(x0)
# Update back to cloud.
for variable in getVariables(localFg)
    updateVariableSolverData!(cloudFg, variable)
end
