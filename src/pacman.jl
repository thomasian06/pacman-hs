
include("ghost_policies.jl")

mutable struct Pacman

    game_size::Int # dimension of square board 
    xp::Int # location of pacman on square board
    ng::Int # number of ghosts on board
    xg::Vector{Int} # array of locations of ghosts on board
    pg::Vector{<:GhostPolicy} # array of the ghost policies
    squares::BitArray{2} # array of actions and squares (have values 0-15 for each square, with a bit describing if an action is available in NESW order, LSB is W, bit 3 is N)
    pellets::BitArray{} # bitmask of the locations of the pellets
    power_pellets::BitArray{} # bitmask of the locations of the power pellets that make the ghosts edible
    power::Bool # if true, pacman can eat the ghosts
    power_count::Int # counter of how many turns pacman has had the power
    power_limit::Int # limit of how many turns pacman has the power

    function Pacman(;
        game_size::Int = 3,
        xp::Int = 1,
        xg::Vector{Int} = [9],
        pg::Vector{<:GhostPolicy} = [RandomGhostPolicy()],
        available_squares::Vector{Int} = [1, 2, 3, 4, 6, 7, 8, 9],
        available_pellets::Vector{},
        available_power_pellets::Vector{},
        power::Bool = false,
        power_count::Int = 0,
        power_limit::Int = 5,
    )

        unique!(available_squares)
        unique!(available_pellets)
        unique!(available_power_pellets)

        squares = generate_squares(game_size, available_squares)
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

        n_squares = game_size^2

        pellets = BitArray{}(undef, n_squares)
        pellets[available_pellets] .= true

        power_pellets = BitArray{}(undef, n_squares)
        power_pellets[available_power_pellets] .= true

        new(
            game_size,
            xp,
            ng,
            xg,
            pg,
            squares,
            pellets,
            power_pellets,
            power,
            power_count,
            power_limit,
        )
    end

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
