module ModelCheckers

export Attr, FPre

import FromFile: @from
import LightGraphs: inneighbors, outneighbors
@from "transition.jl" import PacmanTransitions: PacmanTransition

function Attr(pt::PacmanTransition, F::Set{Int}, p1_states::Set{Int})

    attr_prev = copy(F)
    while true
        attr = union(attr_prev, FPre(pt, attr_prev, p1_states))
        issetequal(attr, attr_prev) ? (return attr) : attr_prev = copy(attr)
    end

end

function FPre(pt::PacmanTransition, F::Set{Int}, p1_states::Set{Int})
    f_pre = Set{Int}()
    for s in F
        union!(f_pre, inneighbors(pt.g, s))
    end

    # states stay if they're in p1 or the set difference between the outneighbors and accepting region is empty
    filter!(x -> x ∈ p1_states || isempty(setdiff(outneighbors(pt.g, x), F)), f_pre)

    return f_pre
end

function find_constrained_path(pt::PacmanTransition, si::Int, sf::Int, region::Set{Int}, reversed::Bool = false)

    si ∉ region && sf ∉ region && (return nothing)
    si == sf && (return nothing)

    next = outneighbors
    reversed && (next = inneighbors)

    v = Set{Int}() # visited states
    q = Queue{Int}() # BFS queue
    enqueue!(q, si)
    while !isempty(q)
        s = dequeue!(q)
        push!(v, s)
        ns = next(pt.g, s)
        

    end

end

end # end module ModelCheckers
