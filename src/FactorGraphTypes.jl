
const FGG = Graphs.GenericIncidenceList{Graphs.ExVertex,Graphs.Edge{Graphs.ExVertex},Array{Graphs.ExVertex,1},Array{Array{Graphs.Edge{Graphs.ExVertex},1},1}}
const FGGdict = Graphs.GenericIncidenceList{Graphs.ExVertex,Graphs.Edge{Graphs.ExVertex},Dict{Int,Graphs.ExVertex},Dict{Int,Array{Graphs.Edge{Graphs.ExVertex},1}}}



mutable struct FactorGraph
  g::FGGdict
  bn
  IDs::Dict{Symbol,Int}
  fIDs::Dict{Symbol,Int}
  id::Int
  nodeIDs::Array{Int,1} # TODO -- ordering seems improved to use adj permutation -- pending merge JuliaArchive/Graphs.jl/#225
  factorIDs::Array{Int,1}
  bnverts::Dict{Int,Graphs.ExVertex} # TODO -- not sure if this is still used, remove
  bnid::Int # TODO -- not sure if this is still used
  dimID::Int
  cg
  cgIDs::Dict{Int,Int} # cgIDs[exvid] = neoid
  sessionname::String
  robotname::String
  registeredModuleFunctions::VoidUnion{Dict{Symbol, Function}}
  reference::VoidUnion{Dict{Symbol, Tuple{Symbol, Vector{Float64}}}}
  stateless::Bool
  FactorGraph() = new()
  FactorGraph(
    x1,
    x2,
    x3,
    x4,
    x5,
    x6,
    x7,
    x8,
    x9,
    x10,
    x11,
    x12,
    x13,
    x14,
    x15,
    x16
   ) = new(
    x1,
    x2,
    x3,
    x4,
    x5,
    x6,
    x7,
    x8,
    x9,
    x10,
    x11,
    x12,
    x13,
    x14,
    x15,
    x16,
    false )
end

"""
    $(SIGNATURES)

Construct an empty FactorGraph object with the minimum amount of information / memory populated.
"""
function emptyFactorGraph(;reference::VoidUnion{Dict{Symbol, Tuple{Symbol, Vector{Float64}}}}=nothing)
    fg = FactorGraph(Graphs.incdict(Graphs.ExVertex,is_directed=false),
                     Graphs.incdict(Graphs.ExVertex,is_directed=true),
                    #  Dict{Int,Graphs.ExVertex}(),
                    #  Dict{Int,Graphs.ExVertex}(),
                     Dict{Symbol,Int}(),
                     Dict{Symbol,Int}(),
                     0,
                     [],
                     [],
                     Dict{Int,Graphs.ExVertex}(),
                     0,
                     0,
                     nothing,
                     Dict{Int,Int}(),
                     "",
                     "",
                     Dict{Symbol, Function}(:IncrementalInference=>IncrementalInference.getSample), # TODO likely to be removed
                     reference  ) #evalPotential
    return fg
end


mutable struct GenericFunctionNodeData{T, S}
  fncargvID::Array{Int,1}
  eliminated::Bool
  potentialused::Bool
  edgeIDs::Array{Int,1}
  frommodule::S #Union{Symbol, AbstractString}
  fnc::T
  GenericFunctionNodeData{T, S}() where {T, S} = new()
  GenericFunctionNodeData{T, S}(x1, x2, x3, x4, x5, x6) where {T, S} = new(x1, x2, x3, x4, x5, x6)
end

FunctionNodeData{T <: Union{InferenceType, FunctorInferenceType}} = GenericFunctionNodeData{T, Symbol}
FunctionNodeData() = GenericFunctionNodeData{T, Symbol}()
FunctionNodeData(x1, x2, x3, x4, x5, x6) = GenericFunctionNodeData{T, Symbol}(x1, x2, x3, x4, x5, x6)

# typealias PackedFunctionNodeData{T <: PackedInferenceType} GenericFunctionNodeData{T, AbstractString}
PackedFunctionNodeData{T <: PackedInferenceType} = GenericFunctionNodeData{T, AbstractString}
PackedFunctionNodeData() = GenericFunctionNodeData{T, AbstractString}()
PackedFunctionNodeData(x1, x2, x3, x4, x5, x6) = GenericFunctionNodeData{T, AbstractString}(x1, x2, x3, x4, x5, x6)


function convert(::Type{PackedVariableNodeData}, d::VariableNodeData)
  return PackedVariableNodeData(d.initval[:],size(d.initval,1),
                              d.initstdev[:],size(d.initstdev,1),
                              d.val[:],size(d.val,1),
                              d.bw[:], size(d.bw,1),
                              d.BayesNetOutVertIDs,
                              d.dimIDs, d.dims, d.eliminated,
                              d.BayesNetVertID, d.separator,
                              string(d.softtype), d.initialized)
end
function convert(::Type{VariableNodeData}, d::PackedVariableNodeData)

  r1 = d.diminitval
  c1 = r1 > 0 ? floor(Int,length(d.vecinitval)/r1) : 0
  M1 = reshape(d.vecinitval,r1,c1)

  r2 = d.diminitdev
  c2 = r2 > 0 ? floor(Int,length(d.vecinitstdev)/r2) : 0
  M2 = reshape(d.vecinitstdev,r2,c2)

  r3 = d.dimval
  c3 = r3 > 0 ? floor(Int,length(d.vecval)/r3) : 0
  M3 = reshape(d.vecval,r3,c3)

  r4 = d.dimbw
  c4 = r4 > 0 ? floor(Int,length(d.vecbw)/r4) : 0
  M4 = reshape(d.vecbw,r4,c4)

  # TODO -- allow out of module type allocation (future feature, not currently in use)
  st = IncrementalInference.ContinuousMultivariate # eval(parse(d.softtype))

  return VariableNodeData(M1,M2,M3,M4, d.BayesNetOutVertIDs,
    d.dimIDs, d.dims, d.eliminated, d.BayesNetVertID, d.separator,
    nothing, st, d.initialized )
end
function VNDencoder(P::Type{PackedVariableNodeData}, d::VariableNodeData)
  return convert(P, d) #PackedVariableNodeData
end
function VNDdecoder(T::Type{VariableNodeData}, d::PackedVariableNodeData)
  return convert(T, d) #VariableNodeData
end


function compare(a::VariableNodeData,b::VariableNodeData)
    TP = true
    TP = TP && a.initval == b.initval
    TP = TP && a.initstdev == b.initstdev
    TP = TP && a.val == b.val
    TP = TP && a.bw == b.bw
    TP = TP && a.BayesNetOutVertIDs == b.BayesNetOutVertIDs
    TP = TP && a.dimIDs == b.dimIDs
    TP = TP && a.dims == b.dims
    TP = TP && a.eliminated == b.eliminated
    TP = TP && a.BayesNetVertID == b.BayesNetVertID
    TP = TP && a.separator == b.separator
    return TP
end

function ==(a::VariableNodeData,b::VariableNodeData, nt::Symbol=:var)
  return IncrementalInference.compare(a,b)
end


# heavy use of multiple dispatch for converting between packed and original data types during DB usage
function convert{T <: InferenceType, P <: PackedInferenceType}(::Type{FunctionNodeData{T}}, d::PackedFunctionNodeData{P})
  return FunctionNodeData{T}(d.fncargvID, d.eliminated, d.potentialused, d.edgeIDs,
          Symbol(d.frommodule), convert(T, d.fnc))
end
function convert{P <: PackedInferenceType, T <: InferenceType}(::Type{PackedFunctionNodeData{P}}, d::FunctionNodeData{T})
  return PackedFunctionNodeData{P}(d.fncargvID, d.eliminated, d.potentialused, d.edgeIDs,
          string(d.frommodule), convert(P, d.fnc))
end


# Functor version -- TODO, abstraction can be improved here
function convert{T <: FunctorInferenceType, P <: PackedInferenceType}(::Type{FunctionNodeData{GenericWrapParam{T}}}, d::PackedFunctionNodeData{P})
  usrfnc = convert(T, d.fnc)
  gwpf = prepgenericwrapper(Graphs.ExVertex[], usrfnc, getSample)
  return FunctionNodeData{GenericWrapParam{T}}(d.fncargvID, d.eliminated, d.potentialused, d.edgeIDs,
          Symbol(d.frommodule), gwpf) #{T}
end
function convert{P <: PackedInferenceType, T <: FunctorInferenceType}(::Type{PackedFunctionNodeData{P}}, d::FunctionNodeData{T})
  return PackedFunctionNodeData{P}(d.fncargvID, d.eliminated, d.potentialused, d.edgeIDs,
          string(d.frommodule), convert(P, d.fnc.usrfnc!))
end

function FNDencode{T <: FunctorInferenceType, P <: PackedInferenceType}(::Type{PackedFunctionNodeData{P}}, d::FunctionNodeData{T})
  return convert(PackedFunctionNodeData{P}, d) #PackedFunctionNodeData{P}
end
function FNDdecode{T <: FunctorInferenceType, P <: PackedInferenceType}(::Type{FunctionNodeData{T}}, d::PackedFunctionNodeData{P})
  return convert(FunctionNodeData{T}, d) #FunctionNodeData{T}
end

function FNDencode{T <: InferenceType, P <: PackedInferenceType}(::Type{PackedFunctionNodeData{P}}, d::FunctionNodeData{T})
  return convert(PackedFunctionNodeData{P}, d) #PackedFunctionNodeData{P}
end
function FNDdecode{T <: InferenceType, P <: PackedInferenceType}(::Type{FunctionNodeData{T}}, d::PackedFunctionNodeData{P})
  return convert(FunctionNodeData{T}, d) #FunctionNodeData{T}
end


# Compare FunctionNodeData
function compare{T,S}(a::GenericFunctionNodeData{T,S},b::GenericFunctionNodeData{T,S})
  # TODO -- beef up this comparison to include the gwp
  TP = true
  TP = TP && a.fncargvID == b.fncargvID
  TP = TP && a.eliminated == b.eliminated
  TP = TP && a.potentialused == b.potentialused
  TP = TP && a.edgeIDs == b.edgeIDs
  TP = TP && a.frommodule == b.frommodule
  TP = TP && typeof(a.fnc) == typeof(b.fnc)
  return TP
end


function addGraphsVert!(fgl::FactorGraph,
            exvert::Graphs.ExVertex;
            labels::Vector{<:AbstractString}=String[])
  #
  Graphs.add_vertex!(fgl.g, exvert)
end

function getVertNode(fgl::FactorGraph, id::Int; nt::Symbol=:var, bigData::Bool=false)
  return fgl.g.vertices[id] # check equivalence between fgl.v/f[i] and fgl.g.vertices[i]
  # return nt == :var ? fgl.v[id] : fgl.f[id]
end
function getVertNode(fgl::FactorGraph, lbl::Symbol; nt::Symbol=:var, bigData::Bool=false)
  return getVertNode(fgl, (nt == :var ? fgl.IDs[lbl] : fgl.fIDs[lbl]), nt=nt, bigData=bigData)
end
getVertNode{T <: AbstractString}(fgl::FactorGraph, lbl::T; nt::Symbol=:var, bigData::Bool=false) = getVertNode(fgl, Symbol(lbl), nt=nt, bigData=bigData)



# excessive function, needs refactoring
function updateFullVertData!(fgl::FactorGraph,
    nv::Graphs.ExVertex;
    updateMAPest::Bool=false )
  #

  # not required, since we using reference -- placeholder function CloudGraphs interface
  # getVertNode(fgl, nv.index).attributes["data"] = nv.attributes["data"]
  nothing
end


function makeAddEdge!(fgl::FactorGraph, v1::Graphs.ExVertex, v2::Graphs.ExVertex; saveedgeID::Bool=true)
  edge = Graphs.make_edge(fgl.g, v1, v2)
  Graphs.add_edge!(fgl.g, edge)
  if saveedgeID push!(getData(v2).edgeIDs,edge.index) end #.attributes["data"]
  edge
end

function graphsOutNeighbors(fgl::FactorGraph, vert::Graphs.ExVertex; ready::Int=1,backendset::Int=1, needdata::Bool=false)
  Graphs.out_neighbors(vert, fgl.g)
end
function graphsOutNeighbors(fgl::FactorGraph, exVertId::Int; ready::Int=1,backendset::Int=1, needdata::Bool=false)
  graphsOutNeighbors(fgl.g, getVert(fgl,exVertId), ready=ready, backendset=backendset, needdata=needdata)
end

function graphsGetEdge(fgl::FactorGraph, id::Int)
  nothing
end

function graphsDeleteVertex!(fgl::FactorGraph, vert::Graphs.ExVertex)
  warn("graphsDeleteVertex! -- not deleting Graphs.jl vertex id=$(vert.index)")
  nothing
end
