
# pacman test files

include("ghost_policies.jl")
include("pacman.jl")

game_size = 3
available_squares = [1, 2, 3, 4, 6, 7, 8, 9]
xp = 1
xg = [9, 8]
ng = 2
pg_types = [:RandomGhostPolicy, :ShortestDistancePolicy]
available_pellets = [2, 3, 4, 7]
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


using GLMakie
using LaTeXStrings

f = Figure(fontsize = 18)

Axis(f[1, 1],
    title = L"\frac{x + y}{\sin(k^2)}",
    xlabel = L"\sum_a^b{xy}",
    ylabel = L"\sqrt{\frac{a}{b}}"
)

f