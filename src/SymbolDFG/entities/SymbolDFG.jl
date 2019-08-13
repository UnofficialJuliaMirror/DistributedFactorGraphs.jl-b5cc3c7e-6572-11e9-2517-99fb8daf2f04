
import ...DistributedFactorGraphs: AbstractDFG, DFGNode, AbstractParams, NoSolverParams


mutable struct SymbolDFG{T <: AbstractParams, V <: DFGNode, F <:DFGNode} <: AbstractDFG
    g::SymbolFactorGraph{V,F}
    description::String
    userId::String
    robotId::String
    sessionId::String
    #NOTE does not exist
    # nodeCounter::Int64
    #NOTE does not exist
    # labelDict::Dict{Symbol, Int64}
    addHistory::Vector{Symbol} #TODO: Discuss more - is this an audit trail?
    solverParams::T # Solver parameters
end

#TODO? do we not want props such as userId, robotId, sessionId, etc...
function SymbolDFG{T,V,F}(g::SymbolFactorGraph{V,F}=SymbolFactorGraph{V,F}();
                           description::String="LightGraphs.jl implementation",
                           userId::String="User ID",
                           robotId::String="Robot ID",
                           sessionId::String="Session ID",
                           params::T=NoSolverParams()) where {T <: AbstractParams, V <:DFGNode, F<:DFGNode}

    SymbolDFG{T,V,F}(g, description, userId, robotId, sessionId, Symbol[], params)
end

Base.propertynames(x::SymbolDFG, private::Bool=false) =
    (:g, :description, :userId, :robotId, :sessionId, :nodeCounter, :labelDict, :addHistory, :solverParams)
        # (private ? fieldnames(typeof(x)) : ())...)

Base.getproperty(x::SymbolDFG,f::Symbol) = begin
    if f == :nodeCounter
        @error "Depreciated? returning number of nodes"
        nv(x.g)
    elseif f == :labelDict
        @error "Maybe depreciated? using internals"
        x.g.fadjdict
    else
        getfield(x,f)
    end
end
