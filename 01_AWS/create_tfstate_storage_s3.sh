#!/bin/bash

if [ $# != 1 ]; then
    echo "Usage: $0 [bucket name]"
    exit 1
fi
bucket_name=$1

# バケットの作成
aws s3api create-bucket --region "ap-northeast-1" --bucket $bucket_name --create-bucket-configuration LocationConstraint="ap-northeast-1"

# アクセス権限の設定
aws s3api put-public-access-block --region "ap-northeast-1" --bucket $bucket_name --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# 履歴の有効化
aws s3api put-bucket-versioning --region "ap-northeast-1" --bucket $bucket_name --versioning-configuration Status=Enabled
