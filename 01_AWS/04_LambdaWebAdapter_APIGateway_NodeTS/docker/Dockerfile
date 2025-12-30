#--------------------------------------------------
# ビルド環境
#--------------------------------------------------
FROM node:24-alpine AS builder

# Express APIサーバーのビルド
COPY node /node
WORKDIR /node
RUN npm install
RUN npm run build


#--------------------------------------------------
# 製品環境
#--------------------------------------------------
FROM gcr.io/distroless/nodejs24-debian12:nonroot AS releaser
USER nonroot

# Lambda Web Adapterをインストール
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.9.1 /lambda-adapter /opt/extensions/lambda-adapter

# Express APIサーバーのインストール
COPY --from=builder /node /node
WORKDIR /node
# ポート8080を公開（Lambda Web Adapterのデフォルト）
EXPOSE 8080
# NODE_ENVを本番環境に設定
ENV NODE_ENV=production
# エントリーポイントの設定
CMD ["/node/dist/index.mjs"]