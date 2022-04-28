
module PacmanTransitions

export PacmanTransition, expand_from_initial_state!

using LightGraphs
import FromFile: @from
@from "pacman.jl" import Pacmen: PacmanGameState, Pacman, update_game_state, findindex
@from "ghost_policies.jl" import GhostPolicies: GhostPolicy, ghost_action, get_available_policy_actions

mutable struct PacmanTransition

    pg::Vector{<:GhostPolicy}
    ng::Int
    squares::BitArray{2}
    actions::Vector{Int}
    game_mode_pellets::Bool
    vertex_data::Vector{PacmanGameState}
    edge_data::Vector{Int} # becomes deterministic_edge_data if nondeterministic
    initial_states::Vector{Int}
    unsafe_states::Vector{Int}
    accepting_states::Vector{Int}
    deterministic::Bool
    deterministic_vertices::Vector{Int} # list of graph indices that are p1 deterministic
    nondeterministic_vertices::Vector{Int} # list of graph indices that are p2 nondeterministic
    nondeterministic_edge_data::Vector{Vector{Int}} # 
    g::SimpleDiGraph

    function PacmanTransition(
        pg::Vector{<:GhostPolicy},
        squares::BitArray{2},
        actions::Vector{Int};
        game_mode_pellets::Bool = false,
    )
        vertex_data = Vector{PacmanGameState}()
        edge_data = Vector{Int}()
        initial_states = Vector{Int}()
        unsafe_states = Vector{Int}()
        accepting_states = Vector{Int}()
        deterministic = true
        ng = length(pg)
        for p in pg
            p.deterministic ? continue : (deterministic = false; break)
        end
        if deterministic
            deterministic_vertices = nothing
            nondeterministic_vertices = nothing
            nondeterministic_edge_data = nothing
        else
            deterministic_vertices = Vector{Int}()
            nondeterministic_vertices = Vector{Int}()
            nondeterministic_edge_data = Vector{Vector{Int}}()
        end
        g = SimpleDiGraph()
        new(
            pg,
            ng,
            squares,
            actions,
            game_mode_pellets,
            vertex_data,
            edge_data,
            initial_states,
            unsafe_states,
            accepting_states,
            deterministic,
            deterministic_vertices,
            nondeterministic_vertices,
            nondeterministic_edge_data,
            g,
        )
    end
end

function LightGraphs.add_vertex!(
    pacman_transition::PacmanTransition,
    game_state::PacmanGameState;
    check::Bool = false,
)
    if check && game_state in pacman_transition.vertex_data
        return false
    end
    push!(pacman_transition.vertex_data, game_state)
    return add_vertex!(pacman_transition.g)
end

function LightGraphs.add_edge!(
    pacman_transition::PacmanTransition,
    a::Int,
    b::Int,
    action::Int,
)
    add_edge!(pacman_transition.g, a, b)
    push!(pacman_transition.edge_data, action)
end

function LightGraphs.add_edge!(
    pacman_transition::PacmanTransition,
    a::Int,
    b::Int,
    action::Vector{Int},
)
    add_edge!(pacman_transition.g, a, b)
    push!(pacman_transition.nondeterministic_edge_data, action)
end

function expand_from_state!(
    pacman_transition::PacmanTransition,
    game_state::PacmanGameState
)

    state_ind = findindex(game_state, pacman_transition.vertex_data)
    if state_ind > 0
        return state_ind
    end
    add_vertex!(pacman_transition, game_state)
    state_ind = nv(pacman_transition.g)
    if game_state.game_over
        push!(pacman_transition.unsafe_states, state_ind)
        if !pacman_transition.deterministic
            push!(pacman_transition.deterministic_vertices, state_ind)
        end
        return state_ind # don't need to progress after unsafe states
    else
        push!(pacman_transition.accepting_states, state_ind)
    end
    available_actions =
        pacman_transition.actions[pacman_transition.squares[game_state.xp, :]]

    if pacman_transition.deterministic

        @inbounds for action in available_actions
            new_game_state = update_game_state(game_state, action, pacman_transition.pg)
            new_state_ind = expand_from_state!(pacman_transition, new_game_state)
            add_edge!(pacman_transition, state_ind, new_state_ind, action)
        end
        return state_ind

    else # nondeterministic transition system

        deterministic_state_ind = state_ind
        push!(pacman_transition.deterministic_vertices, deterministic_state_ind)
        @inbounds for action in available_actions
            xp_new = game_state.xp + action
            list_ghost_actions = Vector{Vector{Int}}()
            for (i, pg) in enumerate(pacman_transition.pg)
                xg = game_state.xg[i]
                available_ghost_actions = get_available_policy_actions(xp_new, xg, pg)
                push!(list_ghost_actions, available_ghost_actions)
            end
            ghost_actions, n_actions = permute_vecvec(list_ghost_actions)
            add_vertex!(pacman_transition, game_state)
            nondeterministic_state_ind = nv(pacman_transition.g)
            push!(pacman_transition.nondeterministic_vertices, nondeterministic_state_ind)
            add_edge!(pacman_transition, deterministic_state_ind, nondeterministic_state_ind, action)
            @inbounds for i = 1:n_actions
                new_game_state = update_game_state(game_state, action, pacman_transition.pg, ghost_actions = ghost_actions[i, :])
                new_state_ind = expand_from_state!(pacman_transition, new_game_state)
                add_edge!(pacman_transition, nondeterministic_state_ind, new_state_ind, ghost_actions[i, :])
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
        for i in 1:n
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
        for i = (next+1):(n - 1)
            inds[i+1] = 1
        end
        count += 1
    end
    return out, n_out
end

function expand_from_initial_state!(
    pacman_transition::PacmanTransition,
    game_state::PacmanGameState,
)
    initial_state_ind = findindex(game_state, pacman_transition.vertex_data)
    if initial_state_ind == 0
        initial_state_ind = expand_from_state!(pacman_transition, game_state)
    end
    if initial_state_ind ∉ pacman_transition.initial_states
        push!(pacman_transition.initial_states, initial_state_ind)
    end

end

end # module PacmanTransitions end
