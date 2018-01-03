```@meta
CurrentModule = QSpatialSearch
```

function initial_state_ctqw(::Type{T}, size::Int) where T<:Number
   fill(T(1/sqrt(size)), size)
end

"""
    initial_state(qss::QSearch{AbstractCTQW})

Returns equal superposition of size `size` and type of `qss.parameters[:hamiltonian]`.

```@docs
julia> qss = QSearch(CTQW(CompleteGraph(4)), [1]);

julia> initial_state(qss)
4-element Array{Complex{Float64},1}:
 0.5+0.0im
 0.5+0.0im
 0.5+0.0im
 0.5+0.0im

```
"""
function initial_state(qss::QSearch{<:AbstractCTQW})
   initial_state_ctqw(eltype(qss.parameters[:hamiltonian]), size(qss.parameters[:hamiltonian],1))
end

"""
    evolve(qss, state, runtime)

Returnes new state creates by evolving `state` by `qss.parameters[:hamiltonian]`
for time `runtime` according to Schrödinger equation.

```@docs
julia> qss = QSearch(CTQW(CompleteGraph(4)), [1]);

julia> evolve(qss, initial_state(qss), 1.)
4-element Array{Complex{Float64},1}:
 -0.128942+0.67431im
  0.219272+0.357976im
  0.219272+0.357976im
  0.219272+0.357976im

```
"""
function evolve(qwe::QWalkEvolution{<:AbstractCTQW},
                state::Vector{<:Number},
                runtime::Real)
   hamiltonian_evolution(qwe.parameters[:hamiltonian], state, runtime)
end

function measure_ctqw(state::Vector{<:Number})
   abs.(state).^2
end

function measure_ctqw(state::Vector{<:Number},
                      vertices::Vector{Int})
   abs.(state[vertices]).^2
end

"""
    measure(::QWalkEvolution{<:AbstractCTQW}, state [, vertices])

Returns the probability of measuring each vertex from `vertices` from `state`
according to AbstractCTQW model. If `vertices` is not provided, full measurement is made.
For AbstractCTQW model measurement is done by taking square of absolute value of all elements
of state.

```@docs
julia> qss = QSearch(CTQW(CompleteGraph(4)), [1]);

julia> measure(qss, [sqrt(0.2), sqrt(0.3), sqrt(0.5)])
3-element Array{Float64,1}:
 0.2
 0.3
 0.5

 julia> measure(qss, [sqrt(0.2), sqrt(0.3), sqrt(0.5)], [2, 3])
 2-element Array{Float64,1}:
  0.3
  0.5

```
"""
function measure(::QWalkEvolution{<:AbstractCTQW}, state)
   measure_ctqw(state)
end

function measure(::QWalkEvolution{<:AbstractCTQW}, state, vertices::Vector{Int})
   measure_ctqw(state, vertices)
end
