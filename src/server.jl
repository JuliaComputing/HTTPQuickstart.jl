module Server

using HTTP: HTTP
using LoggingExtras: LoggingExtras
using Logging: Logging

function streamhandler_error(ex)
    @error(
        "Critical error while handling HTTP request",
        exception = (ex, catch_backtrace())
    )
    return HTTP.Response(500, "Internal server error")
end

function streamhandler(router::HTTP.Router)
    function handle_request(router::HTTP.Router, request::HTTP.Request)::HTTP.Response
        r = try
            router(request)
        catch ex
            get(request.context, :error_handler, streamhandler_error)(ex)
        end
        return r
    end

    return function (stream::HTTP.Stream)
        request::HTTP.Request = stream.message
        if request.method ∉ ("HEAD", "GET")
            request.body = read(stream)
        end
        HTTP.closeread(stream)
        request.response::HTTP.Response = handle_request(router, request)
        request.response.request = request
        HTTP.startwrite(stream)
        if request.method != "HEAD"
            write(stream, request.response.body)
        end
        return nothing
    end
end

mutable struct GCFullMetrics
    @atomic last_time::Float64
    @atomic counter::UInt64
    @atomic last_http_call_time::Float64
end

function streamhandler_autogc(router::HTTP.Router) # you probably don't need to use it
    gcfull_metrics = GCFullMetrics(0.0, 0, 0.0)

    function gcfull_automatic()
        e = @elapsed GC.gc(true)
        @atomic gcfull_metrics.last_time = time()
        @atomic gcfull_metrics.counter += 1
        @debug "GC full run (automatic)" time_taken = e
    end
    

    @atomic gcfull_metrics.last_http_call_time = time()
    @atomic gcfull_metrics.last_time = time()
    gc_event = Base.Event(true)


    Threads.@spawn :default begin # task that runs gc every hour
        while true
            last_gc = gcfull_metrics.last_time
            sleep_time = 3600.0 - (time() - last_gc)
            sleep_time > 0.0 && sleep(sleep_time)
            last_gc == gcfull_metrics.last_time && gcfull_automatic()
        end
    end

    Threads.@spawn :default begin # task that runs gc 5 sec after LAST http call
        while true
            wait(gc_event)
            sleep_time = 5.0 - (time() - gcfull_metrics.last_http_call_time)
            sleep_time > 0.0 && sleep(sleep_time)
            !gc_event.set && gcfull_automatic()
        end
    end

    function handle_request(router::HTTP.Router, request::HTTP.Request)::HTTP.Response
        r = try
            router(request)
        catch ex
            get(request.context, :error_handler, streamhandler_error)(ex)
        end
        
        @atomic gcfull_metrics.last_http_call_time = time()
        notify(gc_event)
        return r
    end

    return function (stream::HTTP.Stream)
        request::HTTP.Request = stream.message
        if request.method ∉ ("HEAD", "GET")
            request.body = read(stream)
        end
        HTTP.closeread(stream)
        request.response::HTTP.Response = handle_request(router, request)
        request.response.request = request
        HTTP.startwrite(stream)
        if request.method != "HEAD"
            write(stream, request.response.body)
        end
        return nothing
    end
end


function start!(router::HTTP.Router; host = "127.0.0.1", port = 8080)
    loglevel = Logging.current_logger().min_level
    httpserver = LoggingExtras.withlevel(loglevel; verbosity = 0) do
        HTTP.listen!(streamhandler(router), host, port)
    end
    @info "HTTP Server started on $host:$port"
    return httpserver
end

end
