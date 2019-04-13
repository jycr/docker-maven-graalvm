# Maven with Graalvm

## Example: build the Quarkus "getting-started" in a "native application" Docker container

1. Create project

```bash
mvn io.quarkus:quarkus-maven-plugin:0.13.1:create \
    -DprojectGroupId=org.acme \
    -DprojectArtifactId=getting-started \
    -DclassName="org.acme.quickstart.GreetingResource" \
    -Dpath="/hello"
```

2. Change .dockerignore file:

```
.git/
target/
src/main/docker/Dockerfile.*
README.md
```

3. Change file `./src/main/docker/Dockerfile.native`:

```
FROM jycr/maven-graalvm:3-jdk-11 AS build-env

ARG JAVA_TOOL_OPTIONS

# Ajust proxy if needed (cf. docker build --build-arg HTTPS_PROXY)
RUN /setupMavenProxy.sh

# initialize cache for "root dependencies"
RUN mvn -B \
    -s /usr/share/maven/ref/settings-docker.xml \
    help:evaluate -Dexpression=settings.localRepository

COPY pom.xml /work/
# initialize cache for "project dependencies"
RUN mvn -B \
    -s /usr/share/maven/ref/settings-docker.xml \
    -f /work/pom.xml \
    dependency:go-offline

# Copy project sources
COPY ./src/ /work/src/

# Build project
RUN mvn -B \
    -s /usr/share/maven/ref/settings-docker.xml \
    -f /work/pom.xml \
    -Pnative \
    compile \
    quarkus:build \
    verify

# Make sure native application has execution flag
RUN chmod 500 /work/target/*-runner

####################################################################################################
# "Runtime" image

FROM gcr.io/distroless/cc

COPY --from=build-env /lib/x86_64-linux-gnu/libz.so.1 /lib/x86_64-linux-gnu/libz.so.1

EXPOSE 8080

COPY --from=build-env \
    /work/target/*-runner \
    /application

CMD ["/application", "-Dquarkus.http.host=0.0.0.0"]
```

4. Build application and "runtime" image:

```bash
docker build \
    --build-arg HTTPS_PROXY \
    -f ./src/main/docker/Dockerfile.native \
    -t quarkus-geeting-started:native \
    .
```

5. Start the application:

```bash
docker run -d -p 9999:8080 quarkus-geeting-started:native
```

6. Test the application

Launch browser to address: http://localhost:9999
