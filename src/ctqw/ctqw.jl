export
   AbstractCTQW,
   CTQW,
   matrix

"""
    AbstractCTQW

Abstract CTQW model. By default evolve according to Schrödinger equation and
performs measurmenet by taking square of absolute values of its elements. Default
representation of `AbstractCTQW` is `CTQW`.
"""
abstract type AbstractCTQW <: QWModelCont end

"""
    CTQW(graph::Graph, matrix::Symbol)

Default representation of `AbstractCTQW`. `matrix` needs to be `:adjacency` or `:laplacian` and defaults
to `:adjacency`.
"""
struct CTQW <: AbstractCTQW
   graph::Graph
   matrix::Symbol
   CTQW(graph::Graph, matrix::Symbol) = matrix ∈ [:adjacency, :laplacian] ? new(graph, matrix) : throw(ErrorException("Only :laplacian and :adjacency is implemented"))
end

"""
    CTQW(graph)

Constructor for CTQW, taking `matrix` to be `:adjacency`.
"""
CTQW(graph::Graph) = CTQW(graph, :adjacency)

"""
    matrix(ctqw::AbstractCTQW)

Returns the matrix symbol defining matrix graph used.
"""
matrix(ctqw::AbstractCTQW) = ctqw.matrix

"""
    proj(::Type{Number}, i::Int, n::Int)

Return a canonic projection onto `i`-th subspace.
 """
function proj(::Type{T}, i::Int, n::Int) where T<:Number
   result = spzeros(T, n, n)
   result[i,i] = 1
   result
end

"""
    check_ctqw(ctqw::AbstractCTQW, parameters::Dict{Symbol})

Private functions which checks the existance of `:hamiltonian`, its type and
dimensionality.
"""
function check_ctqw(ctqw::AbstractCTQW,
                    parameters::Dict{Symbol})
   @assert :hamiltonian ∈ keys(parameters) "parameters needs to have key hamiltonian"
   @assert isa(parameters[:hamiltonian], SparseMatrixCSC{<:Number}) || isa(hamiltonian, Matrix{<:Number}) "value for :hamiltonian needs to be Matrix with numbers"
   @assert size(parameters[:hamiltonian], 1) == size(parameters[:hamiltonian], 2) == nv(ctqw.graph) "Hamiltonian needs to be square matrix of order equal to graph order"
   nothing
end

"""
    QWSearch([type::Type{T}, ]ctqw::AbstractCTQW, marked::Vector{Int}[, penalty::Real, jumpingrate::T]) where T<:Number

Creates `QWSearch` according to `AbstractCTQW` model. By default `type` equals
`Complex128`, `jumpingrate` equals largest eigenvalue of adjacency matrix of graph if
`matrix(CTQW)` outputs `:adjacency` and error otherwise, and `penalty` equals 0.
The hamiltonian is `SparseMatrixCSC`.

    QWSearch(qws::QWSearch{<:CTQW}; marked, penalty)

Updates quantum walk search to new subset of marked elements and new penalty. By
default marked and penalty are the same as in qws.
"""
function QWSearch(::Type{T},
                  ctqw::AbstractCTQW,
                  marked::Vector{Int},
                  penalty::Real = 0.,
                  jumpingrate::T = jumping_rate(T, ctqw)) where T<:Number
   hamiltonian = jumpingrate*graph_hamiltonian(T, ctqw)
   hamiltonian += sum(proj(T, v, nv(ctqw.graph)) for v=marked)

   parameters = Dict{Symbol,Any}(:hamiltonian => hamiltonian)

   QWSearch(ctqw, parameters, marked, penalty)
end,

function QWSearch(ctqw::AbstractCTQW,
                  marked::Vector{Int},
                  penalty::Real = 0.,
                  jumpingrate::Real = jumping_rate(Float64, ctqw))
   QWSearch(Complex128, ctqw, marked, penalty, Complex128(jumpingrate))
end,

function QWSearch(qws::QWSearch{<:CTQW};
                  marked::Vector{Int}=qws.marked,
                  penalty::Real=qws.penalty)
   oldmarked = qws.marked

   hamiltonian = copy(parameters(qws)[:hamiltonian])
   hamiltonian += sum(proj(eltype(hamiltonian), v, nv(graph(qws))) for v=marked)
   hamiltonian -= sum(proj(eltype(hamiltonian), v, nv(graph(qws))) for v=oldmarked)

   QWSearch(model(qws), Dict(:hamiltonian => hamiltonian), marked, penalty)
end


"""
    check_qwdynamics(QWSearch, ctqw::AbstractCTQW, parameters::Dict{Symbol}, marked::Vector{Int})

Checks whetver combination of `ctqw`, `marked` and `parameters` produces valid
`QWSearch` object. It checks if `parameters` consists of key `:hamiltonian` with
corresponding value being `SparseMatrixCSC` or `Matrix`. Furthermore the hamiltonian
needs to be square of size equals to `graph(ctqw)` order. the hermiticity is
not checked for efficiency issue.
"""
function check_qwdynamics(::Type{QWSearch},
                          ctqw::AbstractCTQW,
                          parameters::Dict{Symbol},
                          marked::Vector{Int})
   check_ctqw(ctqw, parameters)
end

"""
    QWEvolution([type::Type{Number}, ]ctqw::AbstractCTQW)

Creates `QWEvolution` according to `AbstractCTQW` model. By default `type` equals
`Complex128`. The hamiltonian is `SparseMatrixCSC`.
"""
function QWEvolution(::Type{U},
                     ctqw::AbstractCTQW) where U<:Number
   parameters = Dict{Symbol,Any}(:hamiltonian => graph_hamiltonian(U, ctqw))
   QWEvolution(ctqw, parameters)
end

function QWEvolution(ctqw::AbstractCTQW)
   QWEvolution(Complex128, ctqw)
end

"""
    check_qwdynamics(QWEvolution, ctqw::AbstractCTQW, parameters::Dict{Symbol})

Checks iof combination of `ctqw` and `parameters` produces valid
`QWSearch` object. It checks if `parameters` consists of key `:hamiltonian` with
corresponding value being `SparseMatrixCSC` or `Matrix`. Furthermore the hamiltonian
needs to be square of size equals to `graph(ctqw)` order. The hermiticity is
not checked for efficiency issues.
"""
function check_qwdynamics(::Type{QWEvolution},
                          ctqw::AbstractCTQW,
                          parameters::Dict{Symbol})
   check_ctqw(ctqw, parameters)
end

include("ctqw_utils.jl")
include("ctqw_evolution.jl")