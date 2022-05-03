module PlayGame

export run_reachability, run_safety

import FromFile: @from

using LightGraphs

@from "pacman.jl" using Pacmen
@from "transition.jl" using PacmanTransitions
@from "model_checkers.jl" using ModelCheckers

function run_safety(pacman::Pacman, num_moves_animation::Int = 20, filename::String = "safety_animation.gif")

    xp = pacman.game_state.xp
    xg = pacman.game_state.xg
    available_squares = pacman.available_squares
    available_pellets = pacman.available_pellets
    game_mode_pellets = pacman.game_mode_pellets
    game_size = pacman.game_size
    game_state = pacman.game_state
    squares = pacman.squares
    pg = pacman.pg
    pg_types = pacman.pg_types
    actions = pacman.actions
    game_mode_pellets = pacman.game_mode_pellets

    # generate the pacman transition automaton
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

    unsafe_region, action_map = Attr(pt, pt.unsafe, pt.nondeterministic_vertices)

    safe_region =
        setdiff(union(pt.deterministic_vertices, pt.nondeterministic_vertices), unsafe_region)

    winning_region = intersect(safe_region, pt.initial)

    action_map = get_safe_actions(pt, safe_region)

    pacman_start = Set{Int}()
    for s in collect(winning_region)
        push!(pacman_start, pt.vertex_data[s].xp)
    end

    pacman_start

    winning_tiles = collect(pacman_start)

    ## play pacman safety game

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

    @time for i = 1:num_moves_animation
        current_edge = action_map[findfirst(x -> x.src == current_node, action_map)]
        action = current_edge.act
        update_pacman!(pacman, action)
        current_node = current_edge.dst
        if !pt.deterministic
            O = outneighbors(pt.g, current_node)
            for o in O
                equals(pacman.game_state, pt.vertex_data[o]) && (current_node = o; break)
            end
        end
    end

    # visualize
    visualize_game_history(pacman, winning_tiles, filename)

end

function run_reachability(pacman::Pacman, filename::String = "reachability_animation.gif")

    xp = pacman.game_state.xp
    xg = pacman.game_state.xg
    available_squares = pacman.available_squares
    available_pellets = pacman.available_pellets
    game_mode_pellets = pacman.game_mode_pellets
    game_size = pacman.game_size
    game_state = pacman.game_state

    squares = pacman.squares
    pg = pacman.pg
    pg_types = pacman.pg_types
    actions = pacman.actions
    game_mode_pellets = pacman.game_mode_pellets

    # generate the pacman transition automaton
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


    # SAFETY REGION COMPUTATION 
    attr, action_map = Attr(pt, pt.accepting, pt.deterministic_vertices)

    winning_region = intersect(attr, pt.initial)

    pacman_start = Set{Int}()
    for s in collect(winning_region)
        push!(pacman_start, pt.vertex_data[s].xp)
    end
    winning_tiles = collect(pacman_start)

    @show available_squares
    @show winning_region

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

    while !pacman.game_state.game_over
        current_edge = action_map[findfirst(x -> x.src == current_node, action_map)]
        action = current_edge.act
        update_pacman!(pacman, action)
        current_node = current_edge.dst
        if !pt.deterministic
            O = outneighbors(pt.g, current_node)
            for o in O
                equals(pacman.game_state, pt.vertex_data[o]) && (current_node = o; break)
            end
        end
    end

    visualize_game_history(pacman, winning_tiles, filename)

    return true

end

end # module PlayGame end