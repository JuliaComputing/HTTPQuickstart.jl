# HTTPQuickstart.jl

This repository contains an HTTP server set up in Julia.
The goal is not to be a perfect and universal template, but rather an example of how to set up
a proper HTTP server and features often appearing together such as OpenTelemetry.

It features:

1. A simple streamhandler setup
2. A simple router setup
3. Examples of handler implementations
3. OpenTelemetry: metrics (setup and export config)
4. OpenTelemetry: traces on all incoming requests through middleware (setup and export config)
5. An Auto-GC implementation in `streamhandler_autogc` (not enabled by default) for bad cases of memory leaks on 1.9

## Other features

1. `run.sh` is configured to use `--threads=2,1` by default
2. An example of a Dockerfile (use `make image` to build using the provided target)
3. `extras/run_container.sh` is provided as an example of runtime in a container with **memory limits** applied
4. `extras/run_bench.sh` is provided as an example of performance testing using `ab`
5. `extras/run_otel.sh` is provided as an example of a trace exporting setup with `jaeger`
    1. Tracing setup requires an OpenTelemetry collector running and `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` env pointed at its http receiver.

## Entrypoints

Commands may require `julia`, `ab`, `docker` (usable as non-root) and `make`.

1. From interactive Julia: 
    1. `julia --threads=2,1 --project=.`, then
    2. `using HTTPQuickstart; HTTPQuickstart.main()`
2. From shell using Julia: `julia --threads=2,1 --project=. run.jl`
2. From shell using a script `bash run.sh`
3. From shell in docker `bash extras/run_container.sh`
