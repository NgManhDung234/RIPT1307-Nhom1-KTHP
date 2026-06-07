FROM node:18-alpine

WORKDIR /app

COPY . .

RUN npm install --legacy-peer-deps

RUN npx tsc -p tsconfig.backend.json

EXPOSE 8080

ENV NODE_ENV=production
ENV PORT=8080

CMD ["node", "dist-backend/index.js"]
