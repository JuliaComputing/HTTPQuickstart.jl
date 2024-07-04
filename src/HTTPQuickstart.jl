module HTTPQuickstart

include("otel_middleware.jl")
include("server.jl")
include("main.jl")
using .MainModule: main

end
