# syntax=docker/dockerfile:1.6
FROM eclipse-temurin:17-jre-jammy

# Use bash with pipefail for safer RUN scripts
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Minimal runtime deps; bash is used by install.sh entrypoint.
RUN apt-get update && apt-get install -y --no-install-recommends \
      bash ca-certificates curl tzdata fontconfig fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

# Use a non-root user (official TB images often run as UID 799)
RUN useradd -u 799 -r -m -d /usr/share/thingsboard -s /bin/bash thingsboard

WORKDIR /usr/share/thingsboard

# Create expected directories
RUN mkdir -p bin/install conf data logs \
    && mkdir -p /var/log/thingsboard \
    && chown -R thingsboard:thingsboard /usr/share/thingsboard /var/log/thingsboard

# Copy ThingsBoard build artifacts produced by Maven build
# Expect these paths after building ThingsBoard (application/target/...) [1](https://bing.com/search?q=Dockerfile+heredoc+RUN+%3c%3cEOF+unterminated+heredoc+BuildKit+docker%2fdockerfile+1.6)[2](https://github.com/moby/buildkit/issues/5265)
COPY application/target/*-boot.jar /usr/share/thingsboard/bin/thingsboard.jar
COPY application/target/conf/ /usr/share/thingsboard/conf/
COPY application/target/bin/install/ /usr/share/thingsboard/bin/install/

# Ensure install script is executable and permissions are correct
RUN chmod +x /usr/share/thingsboard/bin/install/install.sh \
    && chown -R thingsboard:thingsboard /usr/share/thingsboard /var/log/thingsboard

# Create entrypoint script (robust BuildKit heredoc, no \n\ hacks) [3](https://www.ipv6.rs/tutorial/macOS/Thingsboard/)[4](https://stackoverflow.com/questions/58482174/thingsboard-installation-failed-on-ubuntu)
RUN <<'EOF'
cat > /usr/local/bin/tb-entrypoint.sh <<'SCRIPT_EOF'
#!/usr/bin/env bash
set -euo pipefail

INSTALL_TB_VAL="${INSTALL_TB:-false}"
LOAD_DEMO_VAL="${LOAD_DEMO:-false}"

if [[ "${INSTALL_TB_VAL}" == "true" ]]; then
  echo "[tb-entrypoint] INSTALL_TB=true -> running installation"
  if [[ "${LOAD_DEMO_VAL}" == "true" ]]; then
    echo "[tb-entrypoint] LOAD_DEMO=true -> using --loadDemo"
    /usr/share/thingsboard/bin/install/install.sh --loadDemo
  else
    /usr/share/thingsboard/bin/install/install.sh
  fi
  echo "[tb-entrypoint] Installation complete"
  exit 0
fi

echo "[tb-entrypoint] Starting ThingsBoard"
exec java ${JAVA_OPTS:-} -jar /usr/share/thingsboard/bin/thingsboard.jar
SCRIPT_EOF

chmod +x /usr/local/bin/tb-entrypoint.sh
chown 799:799 /usr/local/bin/tb-entrypoint.sh
EOF

USER 799

EXPOSE 8080 7070 1883 8883 5683-5688/udp

ENTRYPOINT ["/usr/local/bin/tb-entrypoint.sh"]