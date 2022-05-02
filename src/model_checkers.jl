module ModelCheckers

export Attr, FPre

import FromFile: @from
import LightGraphs: inneighbors, outneighbors
@from "transition.jl" import PacmanTransitions: PacmanTransition, DEdge, NDEdge

function Attr(pt::PacmanTransition, F::Set{Int}, p1_states::Set{Int})

    any(x -> x.src ∈ p1_states, pt.edge_data) ? action_map = Set{DEdge}() :
    action_map = Set{NDEdge}()

    attr_prev = copy(F)
    while true
        attr = union(attr_prev, FPre!(pt, attr_prev, p1_states, action_map))
        issetequal(attr, attr_prev) ? (return attr, action_map) : attr_prev = copy(attr)
    end

end

function FPre!(
    pt::PacmanTransition,
    F::Set{Int},
    p1_states::Set{Int},
    action_map::Set{DEdge},
)
    f_pre = Set{Int}()
    for s in F
        union!(f_pre, inneighbors(pt.g, s))
    end

    # states stay if they're in p1 or the set difference between the outneighbors and accepting region is empty
    filter!(x -> x ∈ p1_states || isempty(setdiff(outneighbors(pt.g, x), F)), f_pre)

    new_s = setdiff(f_pre, F)
    intersect!(new_s, p1_states)

    for s in new_s
        sF = first(intersect(outneighbors(pt.g, s), F))
        push!(
            action_map,
            pt.edge_data[findfirst(x -> x.src == s && x.dst == sF, pt.edge_data)],
        )
    end

    return f_pre
end

function FPre!(
    pt::PacmanTransition,
    F::Set{Int},
    p1_states::Set{Int},
    action_map::Set{NDEdge},
)
    f_pre = Set{Int}()
    for s in F
        union!(f_pre, inneighbors(pt.g, s))
    end

    # states stay if they're in p1 or the set difference between the outneighbors and accepting region is empty
    filter!(x -> x ∈ p1_states || isempty(setdiff(outneighbors(pt.g, x), F)), f_pre)

    new_s = setdiff(f_pre, F)
    intersect!(new_s, p1_states)

    for s in new_s
        sF = first(intersect(outneighbors(pt.g, s), F))
        push!(
            action_map,
            pt.nondeterministic_edge_data[findfirst(
                x -> x.src == s && x.dst == sF,
                pt.nondeterministic_edge_data,
            )],
        )
    end

    return f_pre
end

end # end module ModelCheckers
