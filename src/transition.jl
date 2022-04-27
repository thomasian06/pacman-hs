
module PacmanTransitions

export PacmanTransition, expand_from_initial_state!

using LightGraphs
import FromFile: @from
@from "pacman.jl" import Pacmen: PacmanGameState, Pacman, update_game_state, findindex
@from "ghost_policies.jl" import GhostPolicies: GhostPolicy, ghost_action

mutable struct PacmanTransition
    pg::Vector{<:GhostPolicy}
    squares::BitArray{2}
    actions::Vector{Int}
    game_mode_pellets::Bool
    vertex_data::Vector{PacmanGameState}
    edge_data::Vector{Int}
    initial_states::Vector{Int}
    unsafe_states::Vector{Int}
    accepting_states::Vector{Int}
    deterministic::Bool
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
        for p in pg
            p.deterministic ? continue : (deterministic = false; break)
        end
        g = SimpleDiGraph()
        new(
            pg,
            squares,
            actions,
            game_mode_pellets,
            vertex_data,
            edge_data,
            initial_states,
            unsafe_states,
            accepting_states,
            deterministic,
            g,
        )
    end
end

function LightGraphs.add_vertex!(
    pacman_transition::PacmanTransition,
    game_state::PacmanGameState,
)
    if game_state in pacman_transition.vertex_data
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

function expand_from_state!(
    pacman_transition::PacmanTransition,
    game_state::PacmanGameState,
)
    state_ind = findindex(game_state, pacman_transition.vertex_data)
    if state_ind > 0
        return state_ind
    end
    add_vertex!(pacman_transition, game_state)
    state_ind = nv(pacman_transition.g)
    if game_state.game_over
        push!(pacman_transition.unsafe_states, state_ind)
        return state_ind # don't need to progress after unsafe states
    else
        push!(pacman_transition.accepting_states, state_ind)
    end
    available_actions =
        pacman_transition.actions[pacman_transition.squares[game_state.xp, :]]
    @inbounds for action in available_actions
        new_game_state = update_game_state(game_state, action, pacman_transition.pg)
        new_state_ind = expand_from_state!(pacman_transition, new_game_state)
        add_edge!(pacman_transition, state_ind, new_state_ind, action)
    end
    return state_ind
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

##

# pacman_trans = SimpleDiGraph()

# add_vertex!(pacman_trans)
# add_vertices!(pacman_trans, 15)
# add_edge!(pacman_trans, 1, 2)

# vertices(pacman_trans)
# edges(pacman_trans)

# outneighbors(pacman_trans, 1)
