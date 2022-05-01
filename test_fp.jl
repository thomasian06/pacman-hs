
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
pg_types = [:RandomGhostPolicy, :ShortestDistancePolicy]
# pg_types = [:RandomGhostPolicy]
available_pellets = [21]

pacman = Pacman(
    game_size = game_size,
    xp = xp,
    xg = xg,
    pg_types = pg_types,
    available_squares = available_squares,
    available_pellets = available_pellets,
    game_mode_pellets = true,
)

# Move up 4 times
update_pacman!(pacman, 1)

# Plot 
visualize_game_history(pacman)

