module ModelCheckers

import FromFile: @from
@from "transition.jl" import PacmanTransitions: PacmanTransition

function i_attractor(p::PacmanTransition, accepting::Vec{Int})

    before = []
    pacman_transition.accepting_states
    for accepting in pacman_transition.accepting_states
        append!(before, inneighbors(pacman_transition.g, accepting))
    end
    unique!(before)

    filter!(X -> any(map(x -> x ∉ accepting, outneighbors(X))), before)

    fpre = []
    for prev in before
        append!(fpre, inneighbors(pacman_transition.g, prev))
    end
    unique!(fpre)
    return fpre

end

end # end module ModelCheckers