# --- Etapa 1: compilar ---
FROM debian:bookworm-slim AS build
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential flex bison make \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY Makefile .
COPY src/ src/
RUN make

# --- Etapa 2: imagen final (ligera) ---
FROM debian:bookworm-slim
WORKDIR /app
COPY --from=build /app/interprete /usr/local/bin/interprete
COPY ejemplos/ ejemplos/
ENTRYPOINT ["interprete"]
CMD ["ejemplos/ejemplo1.cal"]
