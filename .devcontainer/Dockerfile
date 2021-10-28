# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.202.5/containers/java-8/.devcontainer/base.Dockerfile

# [Choice] Debian OS version (use bullseye on local arm64/Apple Silicon): buster, bullseye
ARG VARIANT="bullseye"
FROM mcr.microsoft.com/vscode/devcontainers/java:0-8-${VARIANT}

# [Option] Proxy (ex: http://host:port)
ENV http_proxy ""
ENV https_proxy ""

# [Option] Install Maven
ARG INSTALL_MAVEN="false"
ARG MAVEN_VERSION=""
# [Option] Install Gradle
ARG INSTALL_GRADLE="false"
ARG GRADLE_VERSION=""
# [Option] Install Spring Boot
ARG INSTALL_SPRINGBOOT="false"
ARG SPRINGBOOT_VERSION=""
RUN if [ "${INSTALL_MAVEN}" = "true" ]; then su vscode -c "umask 0002 && . /usr/local/sdkman/bin/sdkman-init.sh && sdk install maven \"${MAVEN_VERSION}\""; fi \
    && if [ "${INSTALL_GRADLE}" = "true" ]; then su vscode -c "umask 0002 && . /usr/local/sdkman/bin/sdkman-init.sh && sdk install gradle \"${GRADLE_VERSION}\""; fi \
    && if [ "${INSTALL_SPRINGBOOT}" = "true" ]; then su vscode -c "umask 0002 && . /usr/local/sdkman/bin/sdkman-init.sh && sdk install springboot \"${SPRINGBOOT_VERSION}\""; fi

# [Choice] Node.js version: none, lts/*, 16, 14, 12, 10
ARG NODE_VERSION="lts/*"
RUN if [ "${NODE_VERSION}" != "none" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

# [Optional] Uncomment this section to install additional OS packages.
RUN apt-get update -q \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -yq install --no-install-recommends zip unzip make

# [Optional] Uncomment this line to install global node packages.
# RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g <your-package-here>" 2>&1

# Copy Maven config file
COPY maven-conf/settings.xml /usr/local/sdkman/candidates/maven/current/conf/settings.xml
# Copy Gradle user config file
RUN mkdir -p /home/vscode/.gradle
COPY gradle-conf/gradle.properties /home/vscode/.gradle/gradle.properties
RUN chown -R vscode:vscode /home/vscode/.gradle
