export
   quantum_search,
   maximize_quantum_search,
   all_quantum_search,
   all_measured_quantum_search

"""
    all_quantum_search
"""
function all_quantum_search(qss::QSearch{<:DiscrQWalk}, runtime::Int)
   @assert runtime>=0 "Parameter 'runtime' needs to be nonnegative"

   result = QSearchState[]
   push!(result, QSearchState(qss, initial_state(qss), 0))

   for t=1:runtime
      push!(result, QSearchState(qss, evolve(qss, result[end]), t))
   end

   result
end

"""
    all_measured_quantum_search
"""
function all_measured_quantum_search(qss::QSearch{<:DiscrQWalk}, runtime::Int)
   @assert runtime>=0 "Parameter 'runtime' needs to be nonnegative"
   result = zeros(Float64, (nv(graph(qss)), runtime+1)) # +1 to include 0

   state = initial_state(qss)
   result[:,1] = measure(qss, state)

   for t=1:runtime
      state = evolve(qss, state)
      result[:,t+1] = measure(qss, state) #evolution starts with t=0
   end

   result
end

"""
    quantum_search
"""
function quantum_search(qss::QSearch{<:DiscrQWalk}, runtime::Int)
   @assert runtime>=0 "Parameter 'runtime' needs to be nonnegative"

   state = initial_state(qss)
   for t=1:runtime
      state = evolve(qss, state)
   end

   QSearchState(qss, state, runtime)
end

"""
    maximize_quantum_search
"""
function maximize_quantum_search(qss::QSearch{<:DiscrQWalk},
                                 runtime::Int = nv(graph(qss)),
                                 mode::Symbol = :maxeff)
   @assert runtime>=0 "Parameter 'runtime' needs to be nonnegative"
   @assert mode ∈ [:firstmaxprob, :firstmaxeff, :maxtimeeff, :maxeff, :maxtimeprob] "Specified stop condition is not implemented"

   best_result = QSearchState(qss, initial_state(qss), qss.penalty)
   state = QSearchState(qss, initial_state(qss), qss.penalty)
   for t=1:runtime
      state = QSearchState(qss, evolve(qss, state), t+qss.penalty)
      stopsearchflag = stopsearch(best_result, state, mode)
      best_result = best(best_result, state, mode)

      if stopsearchflag
         break
      end
   end

   best_result
end

"""
    stopsearch
"""
function stopsearch(previous_state::QSearchState,
                    state::QSearchState,
                    mode::Symbol)
   if mode == :maxeff
      return expected_runtime(previous_state) < state.time
   elseif mode == :firstmaxprob
      return sum(previous_state.probability) > sum(state.probability)
   elseif mode == :firstmaxeff
      return expected_runtime(previous_state) < expected_runtime(state)
   else # include :maxtime case, should be considered by outside loop (hack?)
      return false
   end
end

"""
    best
"""
function best(state1::QSearchState,
              state2::QSearchState,
              mode::Symbol)
   if mode ∈ [:firstmaxprob,:maxtimeprob]
      state1.probability > state2.probability ? state1 : state2
   else
      expected_runtime(state1) < expected_runtime(state2) ? state1 : state2
   end
end
