#-------------------------------------------------------
# ビルド環境
#-------------------------------------------------------
FROM node:22-alpine AS builder

# ビルド
COPY node /node
WORKDIR /node
RUN npm install
RUN npm run build



#-------------------------------------------------------
# 製品環境
#-------------------------------------------------------
FROM node:22-alpine AS releaser

# ビルド成果物のコピー
COPY --from=builder /node /node
CMD ["node", "/node/dist/index.mjs"]
