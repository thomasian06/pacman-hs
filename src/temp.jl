
# pacman test files

include("pacman.jl")

game_size = 3
available_squares = [1, 2, 3, 4, 6, 7, 8, 9]
xp = 1
xg = [9]
ng = 1
available_pellets = [2, 3, 4, 7]
available_power_pellets = [6]
power = false
power_count = 0
power_limit = 3
pacman = Pacman(
    game_size = game_size,
    xp = xp,
    xg = xg,
    available_squares = available_squares,
    available_pellets = available_pellets,
    available_power_pellets = available_power_pellets,
    power = power,
    power_count = power_count,
    power_limit = power_limit,
)
