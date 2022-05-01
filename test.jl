
import FromFile: @from

using LightGraphs

@from "src/pacman.jl" using Pacmen
@from "src/transition.jl" using PacmanTransitions
@from "src/model_checkers.jl" using ModelCheckers

##

# game_size = 2
# available_squares = [1, 2]
# game_size = 3
# available_squares = [1, 2, 3, 4, 6, 7, 8, 9]
game_size = 5
available_squares =
    [1, 2, 3, 4, 5, 6, 8, 10, 11, 12, 13, 14, 15, 16, 18, 20, 21, 22, 23, 24, 25]

xp = 1
xg = [25, 13]
ng = 2
pg_types = [:RandomGhostPolicy, :ShortestDistancePolicy]
available_pellets = [2]

pacman = Pacman(
    game_size = game_size,
    xp = xp,
    xg = xg,
    pg_types = pg_types,
    available_squares = available_squares,
    available_pellets = available_pellets,
    game_mode_pellets = true,
)

# update_game_state(pacman.game_state, 3, pacman.pg, ghost_actions=[1, -3])

squares = pacman.squares
pg = pacman.pg
game_state = pacman.game_state
actions = pacman.actions
game_mode_pellets = true

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

# Base.summarysize(pt)

# unique(
#     vcat(
#         pt.nondeterministic_vertices,
#         pt.deterministic_vertices,
#     ),
# )

# length(pt.nondeterministic_vertices)
# length(pt.deterministic_vertices)

# sum(sum(game_state.pellets) for game_state in pt.vertex_data)

# strongly_connected_components(pt.g)

##

winning_region = Attr(pt, pt.accepting, pt.deterministic_vertices)

