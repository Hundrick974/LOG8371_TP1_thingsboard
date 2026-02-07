# syntax=docker/dockerfile:1.6
# ThingsBoard is built on Java 17 [1](https://thingsboard.io/docs/user-guide/install/building-from-source/)
FROM eclipse-temurin:17-jre-jammy

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
# The jar + install script paths are commonly under application/target [1](https://thingsboard.io/docs/user-guide/install/building-from-source/)[3](https://github.com/thingsboard/thingsboard/issues/13400)
COPY application/target/*-boot.jar /usr/share/thingsboard/bin/thingsboard.jar
COPY application/target/bin/install/install.sh /usr/share/thingsboard/bin/install/install.sh
COPY application/target/conf/thingsboard.conf /usr/share/thingsboard/conf/thingsboard.conf

# logback.xml might exist in your build; keep it optional by copying the whole folder if present.
# If your build does NOT produce it, comment the next line.
COPY application/target/bin/install/logback.xml /usr/share/thingsboard/bin/install/logback.xml

# Make install script executable and set ownership
RUN chmod +x /usr/share/thingsboard/bin/install/install.sh \
    && chown -R thingsboard:thingsboard /usr/share/thingsboard /var/log/thingsboard

# Create an entrypoint that supports:
# - INSTALL_TB=true (runs install.sh once)
# - LOAD_DEMO=true (passes --loadDemo) [2](https://github.com/thingsboard/thingsboard/issues/4442)[4](https://stackoverflow.com/questions/62457507/unexpected-error-during-thingsboard-installation)

RUN cat > /usr/local/bin/tb-entrypoint.sh <<'EOF'\n\

#!/usr/bin/env bash\n\
set -euo pipefail\n\
\n\
INSTALL_TB_VAL=\"${INSTALL_TB:-false}\"\n\
LOAD_DEMO_VAL=\"${LOAD_DEMO:-false}\"\n\
\n\
if [[ \"${INSTALL_TB_VAL}\" == \"true\" ]]; then\n\
  echo \"[tb-entrypoint] INSTALL_TB=true -> running installation\"\n\
  if [[ \"${LOAD_DEMO_VAL}\" == \"true\" ]]; then\n\
    echo \"[tb-entrypoint] LOAD_DEMO=true -> using --loadDemo\"\n\
    /usr/share/thingsboard/bin/install/install.sh --loadDemo\n\
  else\n\
    /usr/share/thingsboard/bin/install/install.sh\n\
  fi\n\
  echo \"[tb-entrypoint] Installation complete\"\n\
  exit 0\n\
fi\n\
\n\
echo \"[tb-entrypoint] Starting ThingsBoard\"\n\
exec java ${JAVA_OPTS:-} -jar /usr/share/thingsboard/bin/thingsboard.jar\n\
EOF\n\
&& chmod +x /usr/local/bin/tb-entrypoint.sh

USER 799

# Standard ports used in your compose
EXPOSE 8080 7070 1883 8883 5683-5688/udp

ENTRYPOINT ["/usr/local/bin/tb-entrypoint.sh"]