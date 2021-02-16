FROM node:12.19.0-alpine3.12 as js-builder

WORKDIR /usr/src/app/

COPY package.json yarn.lock ./
COPY packages packages

RUN yarn install --pure-lockfile --no-progress

COPY Gruntfile.js tsconfig.json .eslintrc .editorconfig .browserslistrc .prettierrc.js ./
COPY public public
COPY tools tools
COPY scripts scripts
COPY emails emails

ENV NODE_ENV production
RUN ./node_modules/.bin/grunt build

# Final stage
FROM registry.access.redhat.com/ubi7/ubi

ENV PATH="/usr/share/grafana/bin:$PATH" \
    GF_PATHS_CONFIG="/etc/grafana/grafana.ini" \
    GF_PATHS_DATA="/var/lib/grafana" \
    GF_PATHS_HOME="/usr/share/grafana" \
    GF_PATHS_LOGS="/var/log/grafana" \
    GF_PATHS_PLUGINS="/var/lib/grafana/plugins" \
    GF_PATHS_PROVISIONING="/etc/grafana/provisioning"

WORKDIR $GF_PATHS_HOME

RUN yum -y install ca-certificates bash tzdata && \
    yum -y install openssl musl-utils

COPY conf ./conf

RUN mkdir -p "$GF_PATHS_HOME/.aws" && \
    mkdir -p "$GF_PATHS_PROVISIONING/datasources" \
             "$GF_PATHS_PROVISIONING/dashboards" \
             "$GF_PATHS_PROVISIONING/notifiers" \
             "$GF_PATHS_LOGS" \
             "$GF_PATHS_PLUGINS" \
             "$GF_PATHS_DATA" && \
    cp "$GF_PATHS_HOME/conf/sample.ini" "$GF_PATHS_CONFIG" && \
    cp "$GF_PATHS_HOME/conf/ldap.toml" /etc/grafana/ldap.toml && \
    chmod 777 /var/lib/grafana

COPY --from=js-builder /usr/src/app/public ./public
COPY --from=js-builder /usr/src/app/tools ./tools
COPY plugins/grafana-piechart-panel-069072c /var/lib/grafana/plugins/grafana-piechart-panel
COPY plugins/flant-statusmap-panel /var/lib/grafana/plugins/flant-statusmap-panel
COPY plugins/farski-blendstat-grafana-d53bf7c /var/lib/grafana/plugins/grafana-blendstat-panel
COPY plugins/simPod-grafana-json-datasource-a041dbf /var/lib/grafana/plugins/grafana-json-over-http-ds
COPY plugins/Vertamedia-clickhouse-grafana-bcee398 /var/lib/grafana/plugins/grafana-clickhouse-source
COPY plugins/alertmanager-datasource /var/lib/grafana/plugins/alertmanager-datasource
COPY plugins/NatelEnergy-grafana-discrete-panel-f434d9f /var/lib/grafana/plugins/NatelEnergy-grafana-discrete-panel-f434d9f
COPY plugins/NovatecConsulting-novatec-service-dependency-graph-panel-7d49605 /var/lib/grafana/plugins/service-dependency-panel-7d49605
COPY plugins/algenty-grafana-flowcharting-276ca4a /var/lib/grafana/plugins/algenty-grafana-flowcharting-276ca4a
COPY grafana-server ./bin/
COPY grafana-cli ./bin/

EXPOSE 3000

COPY ./packaging/docker/run.sh /run.sh

ENTRYPOINT [ "/run.sh" ]
