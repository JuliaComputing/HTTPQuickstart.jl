module Handlers
using HTTP: HTTP

function example_handler(r::HTTP.Request)
    return HTTP.Response(200, "Hello world!")
end

function example_handler_w_context(context::Int)
    return function (r::HTTP.Request)
        return HTTP.Response(200, "Hello world! $(context)")
    end
end

function example_handler_w_thread_offload(r::HTTP.Request)
    @info "Logging from $(Threads.threadpool()) threadpool (should be interactive)" Threads.threadid()
    t = Threads.@spawn :default begin
        @info "Logging from $(Threads.threadpool()) threadpool (should be default)" Threads.threadid()
        HTTP.Response(200, "Hello world!")
    end
    return fetch(t)
end


end
