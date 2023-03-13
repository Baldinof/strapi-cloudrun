
FROM node:16-alpine as build
# Installing libvips-dev for sharp Compatibility
RUN apk update && apk add --no-cache build-base gcc autoconf automake zlib-dev libpng-dev vips-dev > /dev/null 2>&1

ENV LITESTREAM_VERSION=v0.3.8
ADD https://github.com/benbjohnson/litestream/releases/download/${LITESTREAM_VERSION}/litestream-${LITESTREAM_VERSION}-linux-amd64-static.tar.gz /tmp/litestream.tar.gz
RUN tar -C /usr/local/bin -xzf /tmp/litestream.tar.gz

ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
WORKDIR /opt/app
COPY ./package.json ./yarn.lock ./
ENV PATH /opt/node_modules/.bin:$PATH
RUN yarn config set network-timeout 600000 -g && yarn install --production

COPY ./src ./src
COPY ./public ./public
COPY ./tsconfig.json ./tsconfig.json
COPY ./config ./config
COPY ./database ./database

RUN yarn build
FROM node:16-alpine
RUN apk add --no-cache vips-dev



FROM node:16-alpine

COPY --from=build /usr/local/bin/litestream /usr/local/bin/litestream

RUN apk add --no-cache vips-dev tini bash
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
WORKDIR /opt/app
ENV PATH /opt/node_modules/.bin:$PATH
COPY --from=build /opt/app ./
COPY ./docker ./docker
COPY ./docker/litestream.yaml /etc/litestream.yml
COPY ./.env ./
COPY ./favicon.png ./
ENV PORT=1337

ENV DATABASE_FILENAME=/data/database.db

ENTRYPOINT ["/sbin/tini", "--"]
CMD [ "/opt/app/docker/run.sh" ]
