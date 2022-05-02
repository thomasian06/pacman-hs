
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

# update_game_state(pacman.game_state, 3, pacman.pg, ghost_actions=[1, -3])

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

attr, action_map = Attr(pt, pt.unsafe, pt.nondeterministic_vertices, true)

winning_region = intersect(attr, pt.initial)

pacman_start = Set{Int}()
for s in collect(winning_region)
    push!(pacman_start, pt.vertex_data[s].xp)
end

pacman_start

## play pacman game

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

i = 1
@time while !pacman.game_state.game_over
    println(i)
    current_edge = action_map[findfirst(x -> x.src == current_node, action_map)]
    current_node = current_edge.dst
    action = current_edge.act
    update_pacman!(pacman, action)
    i += 1
end

pacman.game_state.win


##

# using DynamicalSystems



# @inline @inbounds function f(s::SVector, p, t)

#     x = s[1]
#     y = s[2]
#     dx = s[3]
#     dy = s[4]



#     return SVector{4}()

# end

# ##

# using DifferentialEquations
# function f(du,u,p,t)
#     du[1] = -u[1]
# end
# u0 = [10.0]
# const V = 1
# prob = ODEProblem(f,u0,(0.0,10.0))
# sol = solve(prob,Tsit5())
# using Plots; plot(sol)
