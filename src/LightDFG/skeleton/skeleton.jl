
"""
	$(TYPEDEF)
Skeleton variable with essentials.
"""
struct SkeletonDFGVariable <: DFGNode
	#TODO define essentials
	label::Symbol
end

"""
	$(TYPEDEF)
Skeleton factor with essentials.
"""
struct SkeletonDFGFactor <: DFGNode
	#TODO define essentials
    label::Symbol
	_variableOrderSymbols::Vector{Symbol}
	#TODO is this ^ not always 2 long, rather use a tuple or static array (should be better if it is not mutable):
	# _variableOrderSymbols::NTuple{2,Symbol}
end

SkeletonDFGFactor(label::Symbol) = SkeletonDFGFactor(label, Symbol[])

"""
    $(SIGNATURES)
Add a DFGVariable to a DFG.
"""
function addVariable!(dfg::LightDFG, variable::SkeletonDFGVariable)::Bool
	#TODO should this be an error
	if haskey(dfg.g.variables, variable.label)
		error("Variable '$(variable.label)' already exists in the factor graph")
	end
	FactorGraphs.addVariable!(dfg.g, variable) || return false

    return true
end

"""
    $(SIGNATURES)
Add a DFGFactor to a DFG.
"""
function addFactor!(dfg::LightDFG, variableLabels::Vector{Symbol}, factor::SkeletonDFGFactor)::Bool
	#TODO should this be an error
	if haskey(dfg.g.factors, factor.label)
		error("Factor '$(factor.label)' already exists in the factor graph")
	end

	append!(factor._variableOrderSymbols, copy(variableLabels))

    return FactorGraphs.addFactor!(dfg.g, variableLabels, factor)
end
