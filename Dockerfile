FROM docker.io/library/node:22-alpine3.19@sha256:9e8f45fc08c709b1fd87baeeed487977f57585f85f3838c01747602cd85a64bb AS node
RUN corepack enable pnpm

FROM gcr.io/distroless/nodejs20-debian12:nonroot@sha256:94d77ed5018ae072449732067c2985d3f2f99ce0fe8b8f244cac122ca69b8e73 AS distroless

ENV NEXT_TELEMETRY_DISABLED 1

FROM node AS dependencies

WORKDIR /srv/src

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile


FROM node AS src

WORKDIR /srv/src

COPY --from=dependencies /srv/src/node_modules ./node_modules
COPY . .

FROM src as build

WORKDIR /srv/src
RUN pnpm next build

FROM distroless AS app

ENV NODE_ENV production

WORKDIR /srv/app

COPY --from=build /srv/src/.next/standalone ./
COPY --from=build /srv/src/.next/static ./.next/static

USER nonroot

EXPOSE 3000

ENV PORT 3000

CMD [ "server.js" ]
