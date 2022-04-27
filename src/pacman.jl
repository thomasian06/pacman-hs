
include("ghost_policies.jl")

struct PacmanGameState
    xp::Int
    xg::Vector{Int}
    game_over::Bool
    pellets::BitArray{}
    power_pellets::BitArray{}
    power::Bool
    power_count::Int
    score::Int
    win::Bool
    function PacmanGameState(
        xp::Int,
        xg::Vector{Int},
        game_over::Bool,
        pellets::BitArray{} = BitArray(0),
        power_pellets::BitArray{} = BitArray(0),
        power::Bool = false,
        power_count::Int = nothing,
        score::Int = nothing,
        win::Bool = false,
    )
        new(xp, xg, game_over, pellets, power_pellets, power, power_count, score, win)
    end
end


mutable struct Pacman

    game_state::PacmanGameState
    game_size::Int # dimension of square board 
    ng::Int # number of ghosts on board
    pg::Vector{<:GhostPolicy} # array of the ghost policies
    squares::BitArray{2} # array of actions and squares (have values 0-15 for each square, with a bit describing if an action is available in NESW order, LSB is W, bit 3 is N)
    actions::Vector{Int}
    power_limit::Int # limit of how many turns pacman has the power
    game_history::Vector{PacmanGameState} # stores game history
    game_mode_pellets::Bool

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
        game_mode_pellets::Bool = false,
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
            PacmanGameState(xp, xg, game_over, pellets, power_pellets, power, power_count, score, win)
        game_history = [game_state]

        new(
            game_state,
            game_size,
            ng,
            pg,
            squares,
            actions,
            power_limit,
            game_history,
            game_mode_pellets,
        )
    end

end

function update_game_state(game_state::PacmanGameState, action::Int, pg::Vector{<:GhostPolicy}; game_mode_pellets::Bool = false, power_limit::Int = 0, )

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

        # update power pellets and power
        
        power_pellets = copy(game_state.power_pellets)
        power = game_state.power
        power_count = game_state.power_count
        if power_pellets[xp]
            power_pellets[xp] = false
            power = true
            power_count = 0
        end

        if power
            power_count += 1
            collision = xg .== xp
            score += sum(collision) * 5
            ng -= sum(collision)
            deleteat!(xg, collision)
            deleteat!(pg, collision)
        end
    else
        score = 0
        power = false
        power_count = 0
        pellets = BitArray(0)
        power_pellets = BitArray(0)
    end

    game_over = game_state.game_over
    win = game_state.win
    if xp in xg && !power
        game_over = true
        win = false
    end

    # update ghosts
    for g = 1:ng
        action = ghost_action(xp, xg[g], pg[g])
        xg[g] += action
    end

    # check again if pacman is on top of any ghost
    if power
        power_count += 1
        collision = xg .== xp
        score += sum(collision) * 5
        ng -= sum(collision)
        deleteat!(xg, collision)
        deleteat!(pg, collision)
    end

    if xp in xg && !power
        game_over = true
        win = false
    end

    # check power count against power limit
    if power_count > power_limit
        power_count = 0
        power = false
    end

    if sum(pellets) == 0 && game_mode_pellets
        win = true
        game_over = true
    end

    new_game_state = PacmanGameState(
        xp,
        xg,
        game_over,
        pellets,
        power_pellets,
        power,
        power_count,
        score,
        win,
    )
    push!(pacman.game_history, new_game_state)

    return new_game_state, pg, ng
end

function update_pacman!(pacman::Pacman, action::Int)
    if action ∉ pacman.actions[pacman.squares[pacman.game_state.xp, :]]
        throw(DomainError(xg, "Action not in available actions."))
    end
    new_game_state, new_pg, new_ng = update_game_state(pacman.game_state, action, pacman.pg, game_mode_pellets = pacman.game_mode_pellets, power_limit = pacman.power_limit)
    push!(pacman.game_history, new_game_state)
    pacman.game_state = deepcopy(new_game_state)
    pacman.pg = copy(new_pg)
    pacman.ng = new_ng
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
