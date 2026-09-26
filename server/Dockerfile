# Construire depuis la RACINE du dépôt : le serveur réutilise le moteur de l'app.
#   docker build -f server/Dockerfile -t tenk-server .
#   docker run -p 8080:8080 -e TRUST_PROXY=1 tenk-server
FROM dart:stable AS build
WORKDIR /app
COPY server/pubspec.yaml server/pubspec.lock ./server/
RUN cd server && dart pub get
COPY lib/game ./lib/game
COPY server ./server
RUN cd server && dart pub get --offline && dart compile exe bin/server.dart -o /app/tenk_server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/tenk_server /app/tenk_server
EXPOSE 8080
ENTRYPOINT ["/app/tenk_server"]
