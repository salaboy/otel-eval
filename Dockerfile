# ---- Build stage ----
FROM eclipse-temurin:21-jdk AS builder
WORKDIR /app

# Cache dependency downloads separately from source
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN ./mvnw dependency:go-offline --batch-mode -q

# Build the fat JAR (.claude/skills is bundled as a classpath resource via pom.xml)
COPY src/ src/
COPY .claude/ .claude/
RUN ./mvnw package -DskipTests --batch-mode -q

# ---- Runtime stage ----
FROM eclipse-temurin:21-jre

# Injected automatically by docker buildx for each platform (e.g. amd64, arm64)
ARG TARGETARCH

ARG KIND_VERSION=v0.24.0
ARG HELM_VERSION=v3.17.3
ARG KUBECTL_VERSION=v1.32.0

# Base utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        jq \
        ca-certificates \
        gnupg \
    && rm -rf /var/lib/apt/lists/*

# kind — Kubernetes-in-Docker (binary, arch-specific)
RUN curl -fsSL "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${TARGETARCH}" \
        -o /usr/local/bin/kind \
    && chmod +x /usr/local/bin/kind

# kubectl — Kubernetes CLI (binary, arch-specific)
RUN curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" \
        -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

# Helm — package manager for Kubernetes (tarball, arch-specific)
RUN curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" \
        -o /tmp/helm.tar.gz \
    && tar -xzf /tmp/helm.tar.gz --strip-components=1 -C /usr/local/bin \
         "linux-${TARGETARCH}/helm" \
    && rm /tmp/helm.tar.gz

# Docker CLI — only the client; the host daemon is mounted via /var/run/docker.sock
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
         -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && . /etc/os-release \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
         https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
         > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/target/otel-eval-*.jar app.jar

EXPOSE 8080

# Mount the host Docker socket so kind can create clusters:
#   docker run -v /var/run/docker.sock:/var/run/docker.sock ...
ENTRYPOINT ["java", "-jar", "app.jar"]
