
import FromFile: @from

using LightGraphs

@from "src/pacman.jl" using Pacmen
@from "src/transition.jl" using PacmanTransitions
@from "src/model_checkers.jl" using ModelCheckers

## safety game

game_size = 5
available_squares =
    [1, 2, 3, 4, 5, 6, 8, 10, 11, 12, 13, 14, 15, 16, 18, 20, 21, 22, 23, 24, 25]

xp = 1
xg = [25]
ng = 1
pg_types = [:RandomGhostPolicy]
available_pellets = []
game_mode_pellets = false

pacman = Pacman(
    game_size = game_size,
    xp = xp,
    xg = xg,
    pg_types = pg_types,
    available_squares = available_squares,
    available_pellets = available_pellets,
    game_mode_pellets = game_mode_pellets,
)

squares = pacman.squares
pg = pacman.pg
game_state = pacman.game_state
actions = pacman.actions
game_mode_pellets = pacman.game_mode_pellets

# generate the pacman transition automaton
pt = PacmanTransition(pg, squares, actions, game_mode_pellets = game_mode_pellets)

@time expand_from_initial_state!(pt, game_state)

@time for xp in available_squares
    pacman = Pacman(
        game_size = game_size,
        xp = xp,
        xg = xg,
        pg_types = pg_types,
        available_squares = available_squares,
        available_pellets = available_pellets,
        game_mode_pellets = game_mode_pellets,
    )
    game_state = pacman.game_state
    expand_from_initial_state!(pt, game_state)
end

pt.vertex_data

unsafe_region, action_map = Attr(pt, pt.unsafe, pt.nondeterministic_vertices)

safe_region =
    setdiff(union(pt.deterministic_vertices, pt.nondeterministic_vertices), unsafe_region)

winning_region = intersect(safe_region, pt.initial)

action_map = get_safe_actions(pt, safe_region)

pacman_start = Set{Int}()
for s in collect(winning_region)
    push!(pacman_start, pt.vertex_data[s].xp)
end

pacman_start

## play pacman safety game

pacman = Pacman(
    game_size = game_size,
    xp = xp,
    xg = xg,
    pg_types = pg_types,
    available_squares = available_squares,
    available_pellets = available_pellets,
    game_mode_pellets = game_mode_pellets,
)

initial_state = pacman.game_state
initial_node = findfirst(x -> equals(x, initial_state, game_mode_pellets), pt.vertex_data)

action_map = collect(action_map)
current_node = initial_node

##
max_num_moves = 10
@time for i = 1:max_num_moves
    current_edge = action_map[findfirst(x -> x.src == current_node, action_map)]
    action = current_edge.act
    update_pacman!(pacman, action)
    current_node = current_edge.dst
    if !pt.deterministic
        O = outneighbors(pt.g, current_node)
        for o in O
            equals(pacman.game_state, pt.vertex_data[o]) && (current_node = o; break)
        end
    end
end


## define pacman reachability game

game_size = 5
available_squares =
    [1, 2, 3, 4, 5, 6, 8, 10, 11, 12, 13, 14, 15, 16, 18, 20, 21, 22, 23, 24, 25]

xp = 2
xg = [25, 13]
ng = 1
pg_types = [:ShortestDistancePolicy, :RandomGhostPolicy]
available_pellets = [8]
game_mode_pellets = true

pacman = Pacman(
    game_size = game_size,
    xp = xp,
    xg = xg,
    pg_types = pg_types,
    available_squares = available_squares,
    available_pellets = available_pellets,
    game_mode_pellets = game_mode_pellets,
)

squares = pacman.squares
pg = pacman.pg
game_state = pacman.game_state
actions = pacman.actions
game_mode_pellets = pacman.game_mode_pellets

pt = PacmanTransition(pg, squares, actions, game_mode_pellets = game_mode_pellets)

@time expand_from_initial_state!(pt, game_state)

@time for xp in available_squares
    pacman = Pacman(
        game_size = game_size,
        xp = xp,
        xg = xg,
        pg_types = pg_types,
        available_squares = available_squares,
        available_pellets = available_pellets,
        game_mode_pellets = game_mode_pellets,
    )
    game_state = pacman.game_state
    expand_from_initial_state!(pt, game_state)
end

pt.vertex_data

attr, action_map = Attr(pt, pt.accepting, pt.deterministic_vertices)

winning_region = intersect(attr, pt.initial)

pacman_start = Set{Int}()
for s in collect(winning_region)
    push!(pacman_start, pt.vertex_data[s].xp)
end

pacman_start

## play pacman reachability game

pacman = Pacman(
    game_size = game_size,
    xp = xp,
    xg = xg,
    pg_types = pg_types,
    available_squares = available_squares,
    available_pellets = available_pellets,
    game_mode_pellets = game_mode_pellets,
)

initial_state = pacman.game_state
initial_node = findfirst(x -> equals(x, initial_state, game_mode_pellets), pt.vertex_data)

action_map = collect(action_map)
current_node = initial_node

@time while !pacman.game_state.game_over
    current_edge = action_map[findfirst(x -> x.src == current_node, action_map)]
    action = current_edge.act
    update_pacman!(pacman, action)
    current_node = current_edge.dst
    if !pt.deterministic
        O = outneighbors(pt.g, current_node)
        for o in O
            equals(pacman.game_state, pt.vertex_data[o]) && (current_node = o; break)
        end
    end
end

pacman.game_state.win

##

import FromFile: @from

using LightGraphs

@from "src/pacman.jl" using Pacmen
@from "src/transition.jl" using PacmanTransitions
@from "src/model_checkers.jl" using ModelCheckers
@from "src/play_game.jl" using PlayGame

## Run safety game 

game_size = 5
available_squares =
    [1, 2, 3, 4, 5, 6, 8, 10, 11, 12, 13, 14, 15, 16, 18, 20, 21, 22, 23, 24, 25]

xp = 1
xg = [25]
ng = 1
pg_types = [:RandomGhostPolicy]
available_pellets = []
game_mode_pellets = false

pacman = Pacman(
    game_size = game_size,
    xp = xp,
    xg = xg,
    pg_types = pg_types,
    available_squares = available_squares,
    available_pellets = available_pellets,
    game_mode_pellets = game_mode_pellets,
)

run_safety(pacman, 20, "safety_animation.gif")

## Run reachability game

game_size = 5
available_squares =
    [1, 2, 3, 4, 5, 6, 8, 10, 11, 12, 13, 14, 15, 16, 18, 20, 21, 22, 23, 24, 25]

xp = 1
xg = [25]
ng = 1
pg_types = [:RandomGhostPolicy]
available_pellets = []
game_mode_pellets = false

pacman = Pacman(
    game_size = game_size,
    xp = xp,
    xg = xg,
    pg_types = pg_types,
    available_squares = available_squares,
    available_pellets = available_pellets,
    game_mode_pellets = game_mode_pellets,
)

run_reachability(pacman, "reachability_animation.gif")