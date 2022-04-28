
module GhostPolicies

export sq2i,
    bfs_map,
    GhostPolicy,
    RandomGhostPolicy,
    DeterministicRoutePolicy,
    ShortestDistancePolicy,
    available_policies,
    policy_map,
    ghost_action,
    get_available_policy_actions

using DataStructures

# utility function

@inline function sq2i(x::Int, available_squares::Vector{Int})
    return findall(available_squares .== x)[1]
end

# Graph Searching

function bfs_map(squares::BitArray{2}, xi::Int)
    ns, na = size(squares)
    jump = Int(sqrt(ns))
    actions = Vector{Int}([jump, 1, -jump, -1])
    available_squares = findall(sum(squares, dims = 2)[:] .> 0)
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
                best_action_to_squares[sq2i(neighbor, available_squares)] =
                    best_action_to_squares[sq2i(current, available_squares)]
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
    deterministic::Bool
    function RandomGhostPolicy(squares::BitArray{2}, actions::Vector{Int})
        new(squares, actions, false)
    end
end

function ghost_action(xp::Int, xg::Int, policy::RandomGhostPolicy)
    return policy.actions[rand(findall(policy.squares[xg, :]))]
end

function get_available_policy_actions(xp::Int, xg::Int, policy::RandomGhostPolicy)
    return policy.actions[findall(policy.squares[xg, :])]
end

struct DeterministicRoutePolicy <: GhostPolicy
    squares::BitArray{2}
    actions::Vector{Int}
    route::Vector{Int}
    deterministic::Bool
    function DeterministicRoutePolicy(squares::BitArray{2}, actions::Vector{Int})
        new([1], [1], [1], true)
    end
end

function ghost_action(xp::Int, xg::Int, policy::DeterministicRoutePolicy)
    return policy.route[xg]
end

function get_available_policy_actions(xp::Int, xg::Int, policy::DeterministicRoutePolicy)
    return [ghost_action(xp, xg, policy)]
end

struct ShortestDistancePolicy <: GhostPolicy
    squares::BitArray{2}
    actions::Vector{Int}
    action_map::Array{Int,2}
    available_squares::Vector{Int}
    deterministic::Bool
    function ShortestDistancePolicy(squares::BitArray{2}, actions::Vector{Int})
        available_squares = findall(sum(squares, dims = 2)[:] .> 0)
        ns = length(available_squares)
        action_map = zeros(Int, (ns, ns))
        for square in available_squares
            action_map[sq2i(square, available_squares), :] = bfs_map(squares, square)
        end
        new(squares, actions, action_map, available_squares, true)
    end
end

function ghost_action(xp::Int, xg::Int, policy::ShortestDistancePolicy)
    return policy.action_map[
        sq2i(xg, policy.available_squares),
        sq2i(xp, policy.available_squares),
    ]
end

function get_available_policy_actions(xp::Int, xg::Int, policy::ShortestDistancePolicy)
    return [ghost_action(xp, xg, policy)]
end

available_policies =
    [:RandomGhostPolicy, :DeterministicRoutePolicy, :ShortestDistancePolicy]
policy_map = Dict{Symbol,Any}(
    :RandomGhostPolicy => RandomGhostPolicy,
    :DeterministicRoutePolicy => DeterministicRoutePolicy,
    :ShortestDistancePolicy => ShortestDistancePolicy,
)


end
