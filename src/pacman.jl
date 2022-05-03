
module Pacmen

export Pacman,
    PacmanGameState,
    update_game_state,
    update_pacman!,
    findindex,
    visualize_game_history,
    equals

import FromFile: @from
@from "ghost_policies.jl" using GhostPolicies

using CairoMakie
using FileIO


export ghost_action,
    available_policies,
    policy_map,
    RandomGhostPolicy,
    DeterministicRoutePolicy,
    ShortestDistancePolicy

struct PacmanGameState
    xp::Int
    xg::Vector{Int}
    game_over::Bool
    pellets::BitArray{}
    score::Int
    win::Bool
    function PacmanGameState(
        xp::Int,
        xg::Vector{Int},
        game_over::Bool,
        pellets::BitArray{} = BitArray(0),
        score::Int = 0,
        win::Bool = false,
    )
        new(xp, xg, game_over, pellets, score, win)
    end
end

function equals(a::PacmanGameState, b::PacmanGameState, game_mode_pellets::Bool = false)
    if !game_mode_pellets
        if a.xp == b.xp && a.game_over == b.game_over && all(a.xg .== b.xg)
            return true
        else
            return false
        end
    else
        if a.xp == b.xp &&
           a.game_over == b.game_over &&
           a.win == b.win &&
           a.score == b.score &&
           all(a.xg .== b.xg) &&
           all(a.pellets .== b.pellets) &&
           return true
        else
            return false
        end
    end
    return false
end

Base.:(==)(a::PacmanGameState, b::PacmanGameState) = equals(a, b)

function Base.in(a::PacmanGameState, A::Vector{PacmanGameState})
    @inbounds for ap in A
        ap == a ? (return true) : continue
    end
    return false
end

function instates(
    a::PacmanGameState,
    A::Vector{PacmanGameState},
    game_mode_pellets::Bool = false,
)
    @inbounds for ap in A
        equals(ap, a, game_mode_pellets) ? (return true) : continue
    end
    return false
end

function findindex(
    a::PacmanGameState,
    A::Vector{PacmanGameState},
    game_mode_pellets::Bool = false,
)
    @inbounds for (i, ap) in enumerate(A)
        equals(ap, a, game_mode_pellets) ? (return i) : continue
    end
    return 0
end


mutable struct Pacman

    game_state::PacmanGameState
    game_size::Int # dimension of square board 
    available_squares::Vector{Int}
    available_pellets::Vector{}
    ng::Int # number of ghosts on board
    pg::Vector{<:GhostPolicy} # array of the ghost policies
    pg_types::Vector{Symbol}
    squares::BitArray{2} # array of actions and squares (have values 0-15 for each square, with a bit describing if an action is available in NESW order, LSB is W, bit 3 is N)
    actions::Vector{Int}
    game_history::Vector{PacmanGameState} # stores game history
    game_mode_pellets::Bool

    function Pacman(;
        game_size::Int = 3,
        xp::Int = 1,
        xg::Vector{Int} = [9],
        pg_types::Vector{Symbol} = [:RandomGhostPolicy],
        available_squares::Vector{Int} = [1, 2, 3, 4, 6, 7, 8, 9],
        available_pellets::Vector{},
        score::Int = 0,
        game_over::Bool = false,
        win::Bool = false,
        game_mode_pellets::Bool = false,
    )

        unique!(available_squares)
        unique!(available_pellets)

        squares = generate_squares(game_size, available_squares)
        actions = Vector{Int}([game_size, 1, -game_size, -1])
        if xp ∉ available_squares
            throw(DomainError(xp, "Pacman isn't in list of available squares."))
        end
        if !all(in(available_squares).(xg))
            throw(DomainError(xg, "At least one Ghost isn't in an available square."))
        end
        if !all(in(available_squares).(available_pellets))
            throw(DomainError(xg, "At least one Pellet isn't in an available square."))
        end

        ng = length(xg)

        pg = [policy_map[s](squares, actions) for s in pg_types]

        n_squares = game_size^2

        pellets = BitArray{}(undef, n_squares)
        pellets[available_pellets] .= true

        if !game_mode_pellets
            pellets = BitArray(0)
            score = 0
            win = false
        end

        if xp in xg
            game_over = true
        end

        game_state = PacmanGameState(xp, xg, game_over, pellets, score, win)
        game_history = [game_state]

        new(
            game_state,
            game_size,
            available_squares,
            available_pellets,
            ng,
            pg,
            pg_types,
            squares,
            actions,
            game_history,
            game_mode_pellets,
        )
    end

end

function update_game_state(
    game_state::PacmanGameState,
    action::Int,
    pg::Vector{<:GhostPolicy};
    game_mode_pellets::Bool = false,
    ghost_actions::Union{Vector{Int},Nothing} = nothing,
)

    xp = game_state.xp + action
    xg = copy(game_state.xg)

    ng = length(pg)

    if game_mode_pellets
        # make updates to pacman board based on new pacman location
        pellets = deepcopy(game_state.pellets)
        score = deepcopy(game_state.score)
        if pellets[xp]
            pellets[xp] = false
            score += 1
        end
    else
        score = 0
        pellets = BitArray(0)
    end

    game_over = game_state.game_over
    win = game_state.win
    if xp in xg
        game_over = true
        win = false
    end

    # update ghosts
    if isnothing(ghost_actions)
        for g = 1:ng
            action = ghost_action(xp, xg[g], pg[g])
            xg[g] += action
        end
    else
        xg .+= ghost_actions
    end

    if xp in xg
        game_over = true
        win = false
    end

    if sum(pellets) == 0 && game_mode_pellets
        win = true
        game_over = true
    end

    new_game_state = PacmanGameState(xp, xg, game_over, pellets, score, win)

    return new_game_state
end

function update_pacman!(pacman::Pacman, action::Int)
    if action ∉ pacman.actions[pacman.squares[pacman.game_state.xp, :]]
        throw(DomainError(xg, "Action not in available actions."))
    end
    new_game_state = update_game_state(
        pacman.game_state,
        action,
        pacman.pg,
        game_mode_pellets = pacman.game_mode_pellets,
    )
    push!(pacman.game_history, new_game_state)
    pacman.game_state = deepcopy(new_game_state)
    return new_game_state
end


function generate_squares(game_size::Int, available_squares::Array{Int})
    max_square = game_size^2
    if any(available_squares .> max_square)
        throw(
            DomainError(
                maximum(available_squares),
                "Square is greater than board game size of $max_square.",
            ),
        )
    end

    if any(available_squares .< 1)
        throw(DomainError(minimum(available_squares), "Square is less than 1."))
    end

    actions = Array{Int}([game_size, 1, -game_size, -1])

    squares = BitMatrix(zeros((max_square, 4)))
    for square in available_squares

        for (i, action) in enumerate(actions)
            if square + action in available_squares
                squares[square, i] = true
            end
        end

        if square <= game_size
            squares[square, 3] = false
        end
        if (square - 1) % game_size == 0
            squares[square, 4] = false
        end
        if (square % game_size) == 0
            squares[square, 2] = false
        end
        if square > ((game_size - 1) * game_size)
            squares[square, 1] = false
        end

    end

    return squares
end

function visualize_game_history(
    pacman::Pacman,
    winning_tiles::Vector{Int64},
    filename::String = "animation.gif",
)
    lp = 0.3  # pacman
    lg = 0.6  # ghosts
    lf = 0.1 # food

    nframes = length(pacman.game_history)
    framerate = 1

    vec_x = repeat(1:pacman.game_size, pacman.game_size)
    vec_y = repeat(1:pacman.game_size, inner = pacman.game_size)
    vec_z = ones(pacman.game_size^2)
    vec_z[pacman.available_squares] .= 0

    # Record animation
    animation_iterator = range(1, length(pacman.game_history))

    # Figure 
    f = Figure(backgroundcolor = :white, resolution = (500, 500))
    ax = Axis(f[1, 1], aspect = 1)
    @show [0, pacman.game_size]
    xlims!(ax, 0.5, pacman.game_size + 0.5)
    ylims!(ax, 0.5, pacman.game_size + 0.5)
    hidedecorations!(ax)

    # Start recording
    record(f, filename, animation_iterator; framerate = framerate) do i

        # Venue
        heatmap!(ax, vec_x, vec_y, vec_z, colormap = Reverse(:tempo))

        # Winning region 
        if !isempty(winning_tiles)
            vec_z_wr = ones(length(winning_tiles))
            heatmap!(
                ax,
                [-1; vec_x[winning_tiles]],
                [-1; vec_y[winning_tiles]],
                [0; vec_z_wr],
                colormap = Reverse(:greens),
            )
        end

        # Pellets
        if pacman.game_mode_pellets
            xf_x = vec_x[pacman.game_history[i].pellets]
            xf_y = vec_y[pacman.game_history[i].pellets]
            for j = 1:sum(pacman.game_history[i].pellets)
                poly!(Circle(Point2f(xf_x[j], xf_y[j]), lf), color = :yellow)
            end
        end

        # Pac-Man
        xp = pacman.game_history[i].xp
        poly!(Circle(Point2f(vec_x[xp], vec_y[xp]), lp), color = :yellow)

        # Ghosts
        for j = 1:pacman.ng
            xg = pacman.game_history[i].xg[j]
            poly!(
                Point2f[
                    (-lg / 2, -lg * sqrt(3) / 6),
                    (lg / 2, -lg * sqrt(3) / 6),
                    (0, lg * sqrt(3) / 3),
                ] .+ Point2f[(vec_x[xg], vec_y[xg])],
                color = :red,
            )
        end
    end

end

end
