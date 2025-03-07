### STAGE 1: Build ###

# We label our stage as ‘builder’
FROM --platform=linux/arm64/v8 node:14.21.2-alpine as builder

COPY package.json package-lock.json ./

## Storing node modules on a separate layer will prevent unnecessary npm installs at each build

RUN npm ci && mkdir /ng-app && mv ./node_modules ./ng-app

WORKDIR /ng-app

COPY . .

## Build the angular app in production mode and store the artifacts in dist folder

RUN npm run ng build -- --configuration="prod" --output-path=dist --base-href="./" --output-hashing=none --build-optimizer=false --vendor-chunk


### STAGE 2: Setup ###

FROM nginx:1.14.1-alpine

## Copy our default nginx config
COPY nginx.conf /etc/nginx/nginx.conf

## Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

## From ‘builder’ stage copy over the artifacts in dist folder to default nginx public folder
COPY --from=builder /ng-app/dist /usr/share/nginx/html

RUN echo "Chat21 Web Widget Started!!"

CMD ["/bin/sh",  "-c",  "envsubst < /usr/share/nginx/html/widget-config-template.json > /usr/share/nginx/html/widget-config.json && exec nginx -g 'daemon off;'"]
