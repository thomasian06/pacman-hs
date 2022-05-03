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
xg = [13, 4, 22]
ng = 1
pg_types = [:ShortestDistancePolicy, :DeterministicRoutePolicy, :ShortestDistancePolicy]
available_pellets = [1, 2, 3, 4, 5, 11, 12, 13, 14, 15]
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

run_reachability(pacman, "reachability_animation.gif")