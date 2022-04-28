
import FromFile: @from

@from "src/pacman.jl" using Pacmen

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
pg_types = [:RandomGhostPolicy, :RandomGhostPolicy]
# pg_types = [:RandomGhostPolicy]
available_pellets = [2]

pacman = Pacman(
    game_size = game_size,
    xp = xp,
    xg = xg,
    pg_types = pg_types,
    available_squares = available_squares,
    available_pellets = available_pellets,
)

# update_game_state(pacman.game_state, 3, pacman.pg, ghost_actions=[1, -3])

##

using LightGraphs
import FromFile: @from
@from "src/transition.jl" using PacmanTransitions

##

squares = pacman.squares
pg = pacman.pg
game_state = pacman.game_state
actions = pacman.actions

pacman_transition = PacmanTransition(pg, squares, actions)

@time expand_from_initial_state!(pacman_transition, game_state)

@time for xp in available_squares
    pacman = Pacman(
        game_size = game_size,
        xp = xp,
        xg = xg,
        pg_types = pg_types,
        available_squares = available_squares,
        available_pellets = available_pellets,
    )
    game_state = pacman.game_state
    expand_from_initial_state!(pacman_transition, game_state)
end

##

pacman_transition.vertex_data
unique(
    vcat(
        pacman_transition.nondeterministic_vertices,
        pacman_transition.deterministic_vertices,
    ),
)

## 

t = plot(pacman_transition.g)

