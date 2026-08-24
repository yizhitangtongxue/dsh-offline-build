# syntax=docker/dockerfile:1

FROM node:22-bookworm AS builder

ARG DSH_VERSION=0.1.1-rc.2
ARG DSH_WEBUI_VERSION=0.3.3

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential python3 git ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable

WORKDIR /opt/dsh/runtime
COPY payload/runtime-package.json ./package.json
COPY payload/runtime-pnpm-workspace.yaml ./pnpm-workspace.yaml
RUN pnpm install --prod --frozen-lockfile=false --config.minimum-release-age=0

ENV DSH_HOME=/opt/dsh-seed
ENV PATH=/opt/dsh/runtime/node_modules/.bin:${PATH}

COPY docker/extra-plugins.txt /tmp/extra-plugins.txt

RUN set -eux; \
    CLI=/opt/dsh/runtime/node_modules/@deepseek-ai/dsh/lib/bin.js; \
    install_plugin() { \
      pkg="$1"; \
      if ! node "$CLI" plugin --profile web add --config.minimum-release-age=0 "$pkg"; then \
        node "$CLI" plugin --profile web approve-builds --all; \
        node "$CLI" plugin --profile web add --config.minimum-release-age=0 "$pkg"; \
      fi; \
    }; \
    install_plugin "@linxin666/dsh-web-ui-all@${DSH_WEBUI_VERSION}"; \
    while IFS= read -r pkg; do \
      pkg="$(printf '%s' "$pkg" | sed 's/#.*//' | xargs)"; \
      [ -z "$pkg" ] || install_plugin "$pkg"; \
    done < /tmp/extra-plugins.txt; \
    node "$CLI" --profile web --dump-config > /tmp/dsh-config.yml; \
    grep -q web-ui-task-board /tmp/dsh-config.yml; \
    grep -q web-ui-git-graph /tmp/dsh-config.yml; \
    grep -q web-ui-plugin-manager /tmp/dsh-config.yml; \
    grep -q web-ui-better-sidebar /tmp/dsh-config.yml


FROM node:22-bookworm-slim AS runtime

ARG DSH_VERSION=0.1.1-rc.2
ARG DSH_WEBUI_VERSION=0.3.3

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git openssh-client tini nginx-light \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/dsh/runtime /opt/dsh/runtime
COPY --from=builder /opt/dsh-seed /opt/dsh-seed
COPY docker/entrypoint.sh /usr/local/bin/dsh-entrypoint
COPY docker/nginx.conf /etc/nginx/nginx.conf
RUN chmod +x /usr/local/bin/dsh-entrypoint \
    && ln -s /opt/dsh/runtime/node_modules/pnpm/bin/pnpm.cjs /usr/local/bin/pnpm

ENV DSH_HOME=/data
ENV DSH_PORT=3080
ENV DSH_WORKSPACE=/workspace
ENV PATH=/opt/dsh/runtime/node_modules/.bin:${PATH}
ENV DSH_IMAGE_VERSION="${DSH_VERSION}-webui-${DSH_WEBUI_VERSION}"

WORKDIR /workspace
VOLUME ["/workspace", "/data"]
EXPOSE 3080

HEALTHCHECK --interval=20s --timeout=5s --start-period=30s --retries=3 \
  CMD curl --fail --silent "http://127.0.0.1:${DSH_PORT}/" >/dev/null || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/dsh-entrypoint"]
