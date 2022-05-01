
module PacmanTransitions

export PacmanTransition, expand_from_initial_state!, DEdge, NDEdge

using LightGraphs
import FromFile: @from
@from "pacman.jl" import Pacmen:
    PacmanGameState, Pacman, update_game_state, findindex, instates
@from "ghost_policies.jl" import GhostPolicies:
    GhostPolicy, ghost_action, get_available_policy_actions

struct DEdge{T<:Int}
    src::T
    dst::T
    act::T
end

struct NDEdge{T<:Int}
    src::T
    dst::T
    act::Vector{T}
end

mutable struct PacmanTransition

    pg::Vector{<:GhostPolicy}
    ng::Int
    squares::BitArray{2}
    actions::Vector{Int}
    game_mode_pellets::Bool
    vertex_data::Vector{PacmanGameState}
    edge_data::Vector{DEdge} # becomes deterministic_edge_data if nondeterministic
    initial::Set{Int}
    unsafe::Set{Int}
    accepting::Set{Int}
    deterministic::Bool
    deterministic_vertices::Set{Int} # set of graph indices that are p1 deterministic
    nondeterministic_vertices::Set{Int} # set of graph indices that are p2 nondeterministic
    nondeterministic_edge_data::Vector{NDEdge} # 
    g::SimpleDiGraph

    function PacmanTransition(
        pg::Vector{<:GhostPolicy},
        squares::BitArray{2},
        actions::Vector{Int};
        game_mode_pellets::Bool = false,
    )
        vertex_data = Vector{PacmanGameState}()
        edge_data = Vector{Int}()
        initial = Set{Int}()
        unsafe = Set{Int}()
        accepting = Set{Int}()
        deterministic = true
        ng = length(pg)
        for p in pg
            p.deterministic ? continue : (deterministic = false; break)
        end
        deterministic_vertices = Set{Int}()
        nondeterministic_vertices = Set{Int}()
        nondeterministic_edge_data = Vector{Vector{Int}}()
        g = SimpleDiGraph()
        new(
            pg,
            ng,
            squares,
            actions,
            game_mode_pellets,
            vertex_data,
            edge_data,
            initial,
            unsafe,
            accepting,
            deterministic,
            deterministic_vertices,
            nondeterministic_vertices,
            nondeterministic_edge_data,
            g,
        )
    end
end

function LightGraphs.add_vertex!(
    pt::PacmanTransition,
    game_state::PacmanGameState;
    check::Bool = false,
)
    if check && instates(game_state, pt.vertex_data, pt.game_mode_pellets)
        return false
    end
    push!(pt.vertex_data, game_state)
    return add_vertex!(pt.g)
end

function LightGraphs.add_edge!(pt::PacmanTransition, a::Int, b::Int, action::Int)
    add_edge!(pt.g, a, b)
    push!(pt.edge_data, DEdge(a, b, action))
end

function LightGraphs.add_edge!(pt::PacmanTransition, a::Int, b::Int, action::Vector{Int})
    add_edge!(pt.g, a, b)
    push!(pt.nondeterministic_edge_data, NDEdge(a, b, action))
end

function expand_from_state!(pt::PacmanTransition, game_state::PacmanGameState)

    state_ind = findindex(game_state, pt.vertex_data, pt.game_mode_pellets)
    if state_ind > 0
        return state_ind
    end

    add_vertex!(pt, game_state)
    state_ind = nv(pt.g)


    if pt.game_mode_pellets # pellets, so reachability game
        if game_state.game_over
            if game_state.win
                push!(pt.accepting, state_ind)
                if !pt.deterministic
                    push!(pt.deterministic_vertices, state_ind)
                end
            else
                push!(pt.unsafe, state_ind)
                if !pt.deterministic
                    push!(pt.deterministic_vertices, state_ind)
                end
            end
            return state_ind # don't need to progress after game over
        end
    else # no pellets, so safety game
        if game_state.game_over
            push!(pt.unsafe, state_ind)
            if !pt.deterministic
                push!(pt.deterministic_vertices, state_ind)
            end
            return state_ind # don't need to progress after unsafe states
        end
    end

    available_actions = pt.actions[pt.squares[game_state.xp, :]]

    if pt.deterministic

        @inbounds for action in available_actions
            new_game_state = update_game_state(
                game_state,
                action,
                pt.pg,
                game_mode_pellets = pt.game_mode_pellets,
            )
            new_state_ind = expand_from_state!(pt, new_game_state)
            add_edge!(pt, state_ind, new_state_ind, action)
        end
        return state_ind

    else # nondeterministic transition system

        deterministic_state_ind = state_ind
        push!(pt.deterministic_vertices, deterministic_state_ind)

        @inbounds for action in available_actions

            xp_new = game_state.xp + action

            list_ghost_actions = Vector{Vector{Int}}()
            for (i, pg) in enumerate(pt.pg)
                xg = game_state.xg[i]
                available_ghost_actions = get_available_policy_actions(xp_new, xg, pg)
                push!(list_ghost_actions, available_ghost_actions)
            end

            ghost_actions, n_actions = permute_vecvec(list_ghost_actions)

            add_vertex!(pt, game_state)
            nondeterministic_state_ind = nv(pt.g)
            push!(pt.nondeterministic_vertices, nondeterministic_state_ind)
            add_edge!(pt, deterministic_state_ind, nondeterministic_state_ind, action)

            @inbounds for i = 1:n_actions
                new_game_state = update_game_state(
                    game_state,
                    action,
                    pt.pg,
                    ghost_actions = ghost_actions[i, :],
                    game_mode_pellets = pt.game_mode_pellets,
                )
                new_state_ind = expand_from_state!(pt, new_game_state)
                add_edge!(
                    pt,
                    nondeterministic_state_ind,
                    new_state_ind,
                    ghost_actions[i, :],
                )
            end
        end

        return state_ind
    end
end

function permute_vecvec(arr::Vector{Vector{Int}})
    n = length(arr)
    inds = ones(Int, size(arr))
    n_out = prod(length(a) for a in arr)
    out = zeros(Int, (n_out, n))
    count = 1
    while count <= n_out
        for i = 1:n
            out[count, i] = arr[i][inds[i]]
        end
        next = n - 1
        while next >= 0 && (inds[next+1] + 1 > length(arr[next+1]))
            next -= 1
        end
        if next < 0
            break
        end
        inds[next+1] += 1
        for i = (next+1):(n-1)
            inds[i+1] = 1
        end
        count += 1
    end
    return out, n_out
end

function expand_from_initial_state!(pt::PacmanTransition, game_state::PacmanGameState)
    initial_state_ind = findindex(game_state, pt.vertex_data, pt.game_mode_pellets)
    if initial_state_ind == 0
        initial_state_ind = expand_from_state!(pt, game_state)
    end
    if initial_state_ind ∉ pt.initial
        push!(pt.initial, initial_state_ind)
    end
    pt.deterministic && (pt.deterministic_vertices = Set{Int}(collect(1:nv(pt.g))))
end

end # module PacmanTransitions end
