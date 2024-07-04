module OTelHTTPMiddleware

using OpenTelemetryAPI: extract_context, with_context, with_span, current_span
using HTTP: HTTP
using URIs: URI

function create_otel_middleware(ignored_paths)
    return function (handler)
        function (request::HTTP.Request)
            route = HTTP.getroute(request)
            if HTTP.getroute(request) ∈ ignored_paths
                handler(request)
            else
                # with_context(extract_context(request.headers)) do # if you want to extract and continue external context
                with_span("$(request.method) $route") do
                    url = URI(request.target)
                    current_span().attributes["http.request.method"] = request.method
                    current_span().attributes["http.request.route"] = route
                    current_span().attributes["url.path"] = url.path
                    current_span().attributes["url.query"] = url.query
                    resp = try
                        handler(request)
                    catch _
                        current_span().attributes["http.response.status_code"] = 500
                        rethrow()
                    end
                    current_span().attributes["http.response.status_code"] = resp.status
                    resp
                end
                # end # if you want to extract and continue external context
            end
        end
    end
end
end
