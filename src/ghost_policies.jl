
using DataStructures

# utility function

function sq2i(x::Int, available_squares::Vector{Int})
    return findall(available_squares .== x)[1]
end

# Graph Searching

function bfs_map(squares::BitArray{2}, xi::Int)
    ns, na = size(squares)
    jump = Int(sqrt(ns))
    actions = Vector{Int}([jump, 1, -jump, -1])
    available_squares = findall(sum(squares, dims=2)[:] .> 0)
    visited = BitArray{}(undef, size(available_squares))
    best_action_to_squares = zeros(Int, size(available_squares))
    current = xi

    q = Queue{Int}()

    visited[sq2i(current, available_squares)] = true
    available_actions = actions[squares[current, :]]
    for action in available_actions
        neighbor = current + action
        best_action_to_squares[sq2i(neighbor, available_squares)] = action
        enqueue!(q, neighbor)
    end

    while !isempty(q)
        current = dequeue!(q)
        available_actions = actions[squares[current, :]]
        for action in available_actions
            neighbor = current + action
            if !visited[sq2i(neighbor, available_squares)]
                visited[sq2i(neighbor, available_squares)] = true
                best_action_to_squares[sq2i(neighbor, available_squares)] = best_action_to_squares[sq2i(current, available_squares)]
                enqueue!(q, neighbor)
            end
        end
    end

    return best_action_to_squares
end




# Define Policies
abstract type GhostPolicy end

struct RandomGhostPolicy <: GhostPolicy
    squares::BitArray{2}
    actions::Vector{Int}
    function RandomGhostPolicy(squares::BitArray{2}, actions::Vector{Int})
        new(squares, actions)
    end
end

function ghost_action(xp::Int, xg::Int, policy::RandomGhostPolicy)
    return policy.actions[rand(findall(policy.squares[xg, :]))]
end

struct DeterministicRoutePolicy <: GhostPolicy
    squares::BitArray{2}
    actions::Vector{Int}
    route::Vector{Int}
    function DeterministicRoutePolicy(squares::BitArray{2}, actions::Vector{Int})
        new([1])
    end
end

function ghost_action(xp::Int, xg::Int, policy::DeterministicRoutePolicy)
    return policy.route[xg]
end

struct ShortestDistancePolicy <: GhostPolicy
    squares::BitArray{2}
    actions::Vector{Int}
    action_map::Array{Int, 2}
    available_squares::Vector{Int}
    function ShortestDistancePolicy(squares::BitArray{2}, actions::Vector{Int})
        available_squares = findall(sum(squares, dims=2)[:] .> 0)
        ns = length(available_squares)
        action_map = zeros(Int, (ns, ns))
        for square in available_squares
            action_map[sq2i(square, available_squares), :] = bfs_map(squares, square)
        end
        new(squares, actions, action_map, available_squares)
    end
end

function ghost_action(xp::Int, xg::Int, policy::ShortestDistancePolicy)
    return policy.action_map[sq2i(xg, policy.available_squares), sq2i(xp, policy.available_squares)]
end


available_policies =
    [:RandomGhostPolicy, :DeterministicRoutePolicy, :ShortestDistancePolicy]
policy_map = Dict{Symbol,Any}(
    :RandomGhostPolicy => RandomGhostPolicy,
    :DeterministicRoutePolicy => DeterministicRoutePolicy,
    :ShortestDistancePolicy => ShortestDistancePolicy,
)
