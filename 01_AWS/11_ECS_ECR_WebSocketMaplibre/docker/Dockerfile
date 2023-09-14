##### Build environment #####
FROM node:16.19-alpine as builder

# ビルド
WORKDIR /websocket
COPY client /websocket/client
COPY server /websocket/server
COPY types /websocket/types
COPY package.json /websocket/package.json
COPY package-lock.json /websocket/package-lock.json
RUN npm install
RUN npm run build

# フロントエンドをサーバーのpublicディレクトリにコピー
RUN cp -r client/dist /websocket/public


##### Production environment #####
FROM node:16.19-alpine as releaser

# Express APIサーバーのインストール
COPY --from=builder /websocket /websocket
WORKDIR /websocket
ENTRYPOINT ["node", "server/dist/index.js"]