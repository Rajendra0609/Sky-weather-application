FROM node:latest AS builder
LABEL maintainer="Raja"
COPY * /opt/weather_app
WORKDIR /opt/weather_app
RUN npm install


FROM node:alpine
LABEL maintainer="Raja"
WORKDIR /opt/weather_app
COPY --from=builder /opt/weather_app/ /opt/weather_app/
RUN apk add --no-cache python3 py3-requests
ENV NODE_VERSION 23.11.0
ENV NODE_ENV=production
EXPOSE 3000
CMD ["npm", "start"]
