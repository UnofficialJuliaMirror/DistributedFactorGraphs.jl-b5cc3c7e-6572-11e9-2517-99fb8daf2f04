module DistributedFactorGraphs

using Base
using DocStringExtensions
using Requires
using Dates
using Distributions

# Entities
include("entities/AbstractTypes.jl")
include("entities/DFGFactor.jl")
include("entities/DFGVariable.jl")

export AbstractDFG
export DFGNode
export DFGFactor
export DFGVariable
export label, timestamp, tags, estimates, estimate, solverData, solverDataDict, id, smallData, bigData
export label, data, id

# Include the Graphs.jl API.
include("services/GraphsDFG.jl")

end
