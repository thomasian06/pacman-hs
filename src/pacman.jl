
include("ghost_policies.jl")

struct PacmanGameState
    xp::Int
    xg::Vector{Int}
    pellets::BitArray{}
    power_pellets::BitArray{}
    power::Bool
    power_count::Int
    score::Int
    game_over::Bool
    win::Bool
    function PacmanGameState(
        xp::Int,
        xg::Vector{Int},
        pellets::BitArray{},
        power_pellets::BitArray{},
        power::Bool,
        power_count::Int,
        score::Int,
        game_over::Bool,
        win::Bool,
    )
        new(xp, xg, pellets, power_pellets, power, power_count, score, game_over, win)
    end
end


mutable struct Pacman

    game_size::Int # dimension of square board 
    xp::Int # location of pacman on square board
    ng::Int # number of ghosts on board
    xg::Vector{Int} # array of locations of ghosts on board
    pg::Vector{<:GhostPolicy} # array of the ghost policies
    squares::BitArray{2} # array of actions and squares (have values 0-15 for each square, with a bit describing if an action is available in NESW order, LSB is W, bit 3 is N)
    actions::Vector{Int}
    pellets::BitArray{} # bitmask of the locations of the pellets
    power_pellets::BitArray{} # bitmask of the locations of the power pellets that make the ghosts edible
    power::Bool # if true, pacman can eat the ghosts
    power_count::Int # counter of how many turns pacman has had the power
    power_limit::Int # limit of how many turns pacman has the power
    score::Int # + 1 for every pellet, + 5 for every ghost
    game_over::Bool # false if pacman hasn't been eaten, true if pacman has been eaten or pacman has reached all pellets
    win::Bool # true if pacman has reached all pellets, false otherwise
    game_history::Vector{PacmanGameState} # stores game history

    function Pacman(;
        game_size::Int = 3,
        xp::Int = 1,
        xg::Vector{Int} = [9],
        pg_types::Vector{Symbol} = [:RandomGhostPolicy],
        available_squares::Vector{Int} = [1, 2, 3, 4, 6, 7, 8, 9],
        available_pellets::Vector{},
        available_power_pellets::Vector{},
        power::Bool = false,
        power_count::Int = 0,
        power_limit::Int = 5,
        score::Int = 0,
        game_over::Bool = false,
        win::Bool = false,
    )

        unique!(available_squares)
        unique!(available_pellets)
        unique!(available_power_pellets)

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
        if !all(in(available_squares).(available_power_pellets))
            throw(
                DomainError(xg, "At least one Power Pellet isn't in an available square."),
            )
        end

        ng = length(xg)

        pg = [policy_map[s](squares, actions) for s in pg_types]

        n_squares = game_size^2

        pellets = BitArray{}(undef, n_squares)
        pellets[available_pellets] .= true

        power_pellets = BitArray{}(undef, n_squares)
        power_pellets[available_power_pellets] .= true



        game_state =
            PacmanGameState(xp, xg, pellets, power_pellets, power, power_count, score, game_over, win)
        game_history = [game_state]

        new(
            game_size,
            xp,
            ng,
            xg,
            pg,
            squares,
            actions,
            pellets,
            power_pellets,
            power,
            power_count,
            power_limit,
            score,
            game_over,
            win,
            game_history,
        )
    end

end

function update_ghost!(pacman::Pacman, g::Int)
    action = ghost_action(pacman.xp, pacman.xg[g], pacman.pg[g])
    pacman.xg[g] += action
    return action
end


function update_pacman!(pacman::Pacman, action::Int)

    if action in pacman.actions[pacman.squares[pacman.xp, :]]
        pacman.xp += action
    else
        throw(DomainError(xg, "Action not in available actions."))
    end

    # make updates to pacman board based on new pacman location
    if pacman.pellets[xp]
        pacman.pellets[xp] = false
        pacman.score += 1
    end

    # update power pellets and power
    if pacman.power_pellets[xp]
        pacman.power_pellets[xp] = false
        pacman.power = true
        pacman.power_count = 0
    end

    if pacman.power
        pacman.power_count += 1
        collision = pacman.xg .== pacman.xp
        pacman.score += sum(collision) * 5
        pacman.ng -= sum(collision)
        deleteat!(pacman.xg, collision)
        deleteat!(pacman.pg, collision)
    end

    if pacman.xp in pacman.xg && !pacman.power
        pacman.game_over = true
        pacman.win = false
    end

    # update ghosts
    for g = 1:pacman.ng
        update_ghost!(pacman, g)
    end

    # check again if pacman is on top of any ghost
    if pacman.power
        pacman.power_count += 1
        collision = pacman.xg .== pacman.xp
        pacman.score += sum(collision) * 5
        pacman.ng -= sum(collision)
        deleteat!(pacman.xg, collision)
        deleteat!(pacman.pg, collision)
    end

    if pacman.xp in pacman.xg && !pacman.power
        pacman.game_over = true
        pacman.win = false
    end

    # check power count against power limit
    if pacman.power_count > pacman.power_limit
        pacman.power_count = 0
        pacman.power = false
    end

    new_game_state = PacmanGameState(
        pacman.xp,
        pacman.xg,
        pacman.pellets,
        pacman.power_pellets,
        pacman.power,
        pacman.power_count,
        pacman.score,
        pacman.game_over,
        pacman.win,
    )
    push!(pacman.game_history, new_game_state)

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

    squares = BitArray{2}(undef, max_square, 4)
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
