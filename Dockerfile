FROM node:18-alpine

WORKDIR /app

COPY package.json yarn.lock ./
COPY backend-package.json ./

RUN yarn install

COPY . .

RUN yarn build

EXPOSE 5000

ENV NODE_ENV=production
ENV BACKEND_PORT=5000

CMD ["node", "dist-backend/index.js"]
