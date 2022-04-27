
module Pacmen

export Pacman, PacmanGameState, update_game_state, update_pacman!, findindex

import FromFile: @from
@from "ghost_policies.jl" using GhostPolicies

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
        score::Int = nothing,
        win::Bool = false,
    )
        new(xp, xg, game_over, pellets, score, win)
    end
end

function compare_game_states(
    a::PacmanGameState,
    b::PacmanGameState,
    game_mode_pellets::Bool = false,
)
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

Base.:(==)(a::PacmanGameState, b::PacmanGameState) = compare_game_states(a, b)

function Base.in(a::PacmanGameState, A::Vector{PacmanGameState})
    @inbounds for ap in A
        ap == a ? (return true) : continue
    end
    return false
end

function findindex(a::PacmanGameState, A::Vector{PacmanGameState})
    @inbounds for (i, ap) in enumerate(A)
        ap == a ? (return i) : continue
    end
    return 0
end

mutable struct Pacman

    game_state::PacmanGameState
    game_size::Int # dimension of square board 
    ng::Int # number of ghosts on board
    pg::Vector{<:GhostPolicy} # array of the ghost policies
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
            ng,
            pg,
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
)

    xp = game_state.xp + action
    xg = copy(game_state.xg)

    ng = length(pg)

    if game_mode_pellets
        # make updates to pacman board based on new pacman location
        pellets = copy(game_state.pellets)
        score = copy(game_state.score)
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
    for g = 1:ng
        action = ghost_action(xp, xg[g], pg[g])
        xg[g] += action
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

end
