abstract type GhostPolicy end

struct RandomGhostPolicy <: GhostPolicy
    a::Int
    function RandomGhostPolicy()
        new(1)
    end
    function RandomGhostPolicy(squares::BitArray{2})
        new(1)
    end
end

struct DeterministicRoutePolicy <: GhostPolicy
    a::Int
    function DeterministicRoutePolicy(squares::BitArray{2})
        new(1)
    end
end

struct ShortestDistancePolicy <: GhostPolicy
    a::Int
    function ShortestDistancePolicy(squares::BitArray{2})
        new(1)
    end
end

available_policies = [:RandomGhostPolicy, :DeterministicRoutePolicy, :ShortestDistancePolicy]
policy_map = Dict{Symbol, Any}(:RandomGhostPolicy => RandomGhostPolicy, :DeterministicRoutePolicy => DeterministicRoutePolicy, :ShortestDistancePolicy => ShortestDistancePolicy)