# Originally from IncrementalInference

abstract type InferenceType end
abstract type PackedInferenceType end

abstract type FunctorInferenceType <: Function end

abstract type InferenceVariable end
abstract type ConvolutionObject <: Function end

abstract type FunctorSingleton <: FunctorInferenceType end
abstract type FunctorPairwise <: FunctorInferenceType end
abstract type FunctorPairwiseMinimize <: FunctorInferenceType end

"""
$(TYPEDEF)
"""
mutable struct GenericFunctionNodeData{T, S}
  fncargvID::Vector{Symbol}
  eliminated::Bool
  potentialused::Bool
  edgeIDs::Array{Int,1}
  frommodule::S #Union{Symbol, AbstractString}
  fnc::T
  multihypo::String # likely to moved when GenericWrapParam is refactored
  certainhypo::Vector{Int}
  GenericFunctionNodeData{T, S}() where {T, S} = new{T,S}()
  GenericFunctionNodeData{T, S}(x1, x2, x3, x4, x5::S, x6::T, x7::String="", x8::Vector{Int}=Int[]) where {T, S} = new{T,S}(x1, x2, x3, x4, x5, x6, x7, x8)
  GenericFunctionNodeData(x1, x2, x3, x4, x5::S, x6::T, x7::String="", x8::Vector{Int}=Int[]) where {T, S} = new{T,S}(x1, x2, x3, x4, x5, x6, x7, x8)
  # GenericFunctionNodeData(x1, x2, x3, x4, x5::S, x6::T, x7::String) where {T, S} = new{T,S}(x1, x2, x3, x4, x5, x6, x7)
end

"""
    $(SIGNATURES)
Fundamental structure for a DFG factor.
"""
mutable struct DFGFactor{T, S} <: AbstractDFGFactor
    label::Symbol
    tags::Vector{Symbol}
    data::GenericFunctionNodeData{T, S}
    ready::Int
    backendset::Int
    _internalId::Int64
    _variableOrderSymbols::Vector{Symbol}
    DFGFactor{T, S}(label::Symbol) where {T, S} = new{T, S}(label, Symbol[], GenericFunctionNodeData{T, S}(), 0, 0, 0, Symbol[])
    DFGFactor{T, S}(label::Symbol, _internalId::Int64) where {T, S} = new{T, S}(label, Symbol[], GenericFunctionNodeData{T, S}(), 0, 0, _internalId, Symbol[])
end

label(f::F) where F <: DFGFactor = f.label
tags(f::F) where F <: DFGFactor = f.tags
"""
    $SIGNATURES

Retrieve solver data structure stored in a factor.
"""
function solverData(f::F) where F <: DFGFactor
  return f.data
end
"""
    $SIGNATURES

Retrieve solver data structure stored in a factor.
"""
function data(f::DFGFactor)::GenericFunctionNodeData
  @warn "data() is deprecated, please use solverData()"
  return f.data
end
"""
    $SIGNATURES

Retrieve solver data structure stored in a factor.
"""
function getData(f::DFGFactor)::GenericFunctionNodeData
  #FIXME but back in later, it just slows everything down
  if !(@isdefined getDataWarnOnce)
    @warn "getData is deprecated, please use solverData(), future warnings in getData is suppressed"
    global getDataWarnOnce = true
  end
  # @warn "getData is deprecated, please use solverData()"
  return f.data
end

internalId(f::F) where F <: DFGFactor = f._internalId

# Simply for convenience - don't export
const PackedFunctionNodeData{T} = GenericFunctionNodeData{T, <: AbstractString}
PackedFunctionNodeData(x1, x2, x3, x4, x5::S, x6::T, x7::String="", x8::Vector{Int}=Int[]) where {T <: PackedInferenceType, S <: AbstractString} = GenericFunctionNodeData(x1, x2, x3, x4, x5, x6, x7, x8)
const FunctionNodeData{T} = GenericFunctionNodeData{T, Symbol}
FunctionNodeData(x1, x2, x3, x4, x5::Symbol, x6::T, x7::String="", x8::Vector{Int}=Int[]) where {T <: Union{FunctorInferenceType, ConvolutionObject}}= GenericFunctionNodeData{T, Symbol}(x1, x2, x3, x4, x5, x6, x7, x8)

"""
    $(SIGNATURES)
Structure for first-class citizens of a DFGFactor.
"""
mutable struct DFGFactorSummary <: AbstractDFGFactor
    label::Symbol
    tags::Vector{Symbol}
    _internalId::Int64
    _variableOrderSymbols::Vector{Symbol}
end

label(f::DFGFactorSummary) = f.label
data(f::DFGFactorSummary) = f.data
tags(f::DFGFactorSummary) = f.tags
internalId(f::DFGFactorSummary) = f._internalId


# SKELETON DFG
"""
	$(TYPEDEF)
Skeleton variable with essentials.
"""
struct SkeletonDFGVariable <: AbstractDFGVariable
	label::Symbol
	tags::Vector{Symbol}
end

SkeletonDFGVariable(label::Symbol) = SkeletonDFGVariable(label, Symbol[])

label(v::SkeletonDFGVariable) = v.label
tags(v::SkeletonDFGVariable) = v.tags
