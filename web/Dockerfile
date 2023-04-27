FROM node:14.17.3-alpine3.14
RUN mkdir /app && \
    chown node:node /app
USER node
WORKDIR /app
COPY --chown=node:node package.json ./
RUN npm config set strict-ssl false; npm install; npm ci
COPY ./server.js ./
EXPOSE 5000
CMD ["npm","start"]
