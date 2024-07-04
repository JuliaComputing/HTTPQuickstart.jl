FROM julia:1.10.4 AS base

WORKDIR /opt/server

COPY --link Project.toml /opt/server/Project.toml
COPY --link Manifest.toml /opt/server/Manifest.toml
RUN julia -t4 --project=. -e "using Pkg; Pkg.instantiate(); Pkg.precompile()"

COPY --link src /opt/server/src
RUN julia -t4 --project=. -e "using Pkg; Pkg.instantiate(); Pkg.precompile()"

COPY --link run.jl /opt/server/run.jl
COPY --link run.sh /opt/server/run.sh

CMD ["bash", "-c", " /opt/server/run.sh"]
