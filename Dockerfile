FROM node:22-slim
WORKDIR /app
COPY server/package*.json ./server/
RUN cd server && npm ci --omit=dev
COPY server/ ./server/
COPY website/ ./website/
ENV PORT=3000
EXPOSE 3000
CMD ["node", "server/server.js"]
