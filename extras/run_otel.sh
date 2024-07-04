# see localhost:16686 for jaeger UI

docker run -d --rm --name jaeger \
  -p 16686:16686 \
  -p 4318:4318 \
  jaegertracing/all-in-one:1.53

export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://localhost:4318
julia --threads=2,1 --project=. run.jl
