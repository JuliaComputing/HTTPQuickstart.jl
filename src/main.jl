module MainModule

include("handlers.jl")
using .Handlers: Handlers

using ..Server: start!
using HTTP: HTTP, Router, register!

# Tracing
const OTEL_IGNORED_PATHS = ("/", "/ready")
using ..OTelHTTPMiddleware: create_otel_middleware
using OpenTelemetryExporterOtlpProtoHttp: OtlpHttpTracesExporter
using OpenTelemetrySDK:
    global_tracer_provider, TracerProvider, BatchSpanProcessor, ConsoleExporter

# Metrics
using OpenTelemetryExporterPrometheus: PrometheusExporter
using OpenTelemetrySDK: global_meter_provider, MeterProvider, MetricReader, Meter, Counter

function setup_otel_traces()
    ENV["OTEL_SERVICE_NAME"] = "example_julia_service"
    ENV["OTEL_RESOURCE_ATTRIBUTES"] = "attribute1=value1"
    traces_endpoint = get(ENV, "OTEL_EXPORTER_OTLP_TRACES_ENDPOINT", "")

    span_processor = if !isempty(traces_endpoint)
        @info "ok"
        BatchSpanProcessor(OtlpHttpTracesExporter())
    else
        BatchSpanProcessor(ConsoleExporter(devnull))
    end

    global_tracer_provider(TracerProvider(; span_processor))
    return nothing
end

function setup_otel_metrics()
    global_meter_provider(MeterProvider())
    m = Meter("demo_metrics")
    c = Counter{UInt}("fruit_counter", m)
    c(2; name = "apple", color = "green")

    @info "Starting metrics server"
    MetricReader(PrometheusExporter(;host="0.0.0.0"))

    # call curl localhost:9496/metrics to see metrics

    return nothing
end

function main()
    host = get(ENV, "HOST", "0.0.0.0")
    port = parse(Int, get(ENV, "PORT", "8080"))

    setup_otel_traces()
    setup_otel_metrics()

    router = Router(
        HTTP.Handlers.default404,
        HTTP.Handlers.default405,
        create_otel_middleware(OTEL_IGNORED_PATHS),
    )
    # router = Router() # or this if you don't want OpenTelemetry.jl

    register!(router, "GET", "/", (r::HTTP.Request) -> HTTP.Response(200, "Hello world!"))
    register!(router, "GET", "/ready", (r::HTTP.Request) -> HTTP.Response(200))
    register!(router, "GET", "/example", Handlers.example_handler)
    register!(router, "GET", "/example_context", Handlers.example_handler_w_context(100))
    register!(router, "GET", "/example_threads", Handlers.example_handler_w_thread_offload)

    server = start!(router; host, port)
    wait()
end

end
