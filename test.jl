
import FromFile: @from

@from "src/pacman.jl" using Pacmen

# game_size = 3
# available_squares = [1, 2, 3, 4, 6, 7, 8, 9]
game_size = 5
available_squares = [1, 2, 3, 4, 5, 6, 8, 10, 11, 12, 13, 14, 15, 16, 18, 20, 21, 22, 23, 24, 25]

xp = 1
xg = [25, 13]
ng = 2
pg_types = [:RandomGhostPolicy, :ShortestDistancePolicy]
available_pellets = [2, 3, 4, 6]
available_power_pellets = [6]
power = false
power_count = 0
power_limit = 3


pacman = Pacman(
    game_size = game_size,
    xp = xp,
    pg_types = pg_types,
    xg = xg,
    available_squares = available_squares,
    available_pellets = available_pellets,
    available_power_pellets = available_power_pellets,
    power = power,
    power_count = power_count,
    power_limit = power_limit,
)

##

using LightGraphs
import FromFile: @from
@from "src/transition.jl" using PacmanTransitions

##

squares = pacman.squares
pg = pacman.pg
game_state = pacman.game_state
actions = pacman.actions

pacman_transition = PacmanTransition()
@time expand_from_initial_state!(pacman_transition, game_state, pg, squares, actions)

##

pacman_transition.vertex_data

outneighbors(pacman_transition.g, 27)