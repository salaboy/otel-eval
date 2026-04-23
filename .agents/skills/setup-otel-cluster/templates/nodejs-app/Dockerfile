FROM node:22-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY src ./src

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

USER nodejs

EXPOSE 3000

ENV NODE_OPTIONS="--require @opentelemetry/auto-instrumentations-node/register"

CMD ["node", "src/index.js"]
