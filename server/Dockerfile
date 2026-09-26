# Construire depuis la RACINE du dépôt : le serveur réutilise le moteur de l'app.
#   docker build -f server/Dockerfile -t tenk-server .
#   docker run -p 127.0.0.1:8080:8080 -e TRUST_PROXY=1 tenk-server
#
# Multi-architecture (amd64 et arm64) SANS émulation : l'étape de compilation
# tourne toujours sur la machine de construction et cross-compile le binaire
# (`dart compile exe --target-arch`) ; seule l'image d'exécution, où rien ne
# s'exécute, est celle de la plateforme visée.
FROM --platform=$BUILDPLATFORM dart:stable AS build
ARG TARGETARCH
WORKDIR /app
COPY server/pubspec.yaml server/pubspec.lock ./server/
RUN cd server && dart pub get
COPY lib/game ./lib/game
COPY server ./server
RUN cd server && dart pub get --offline \
 && case "$TARGETARCH" in \
      amd64) arch=x64 ;; \
      arm64) arch=arm64 ;; \
      *) echo "architecture non prise en charge : $TARGETARCH" >&2; exit 1 ;; \
    esac \
 && dart compile exe bin/server.dart --target-os linux --target-arch "$arch" -o /app/tenk_server

# Les bibliothèques d'exécution de la plateforme VISÉE (le défaut d'une étape sans --platform),
# pas celles de la construction.
FROM dart:stable AS runtime

FROM scratch
COPY --from=runtime /runtime/ /
COPY --from=build /app/tenk_server /app/tenk_server
EXPOSE 8080
ENTRYPOINT ["/app/tenk_server"]
