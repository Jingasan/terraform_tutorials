#!/bin/bash
# ローカルPCからのRDS接続確立用のスクリプト

#============================================================
# 踏み台用のECSコンテナの開始関数
#============================================================
function start_container () {
  echo "---------------------------------------------"
  echo "1. Start bastion container"
  echo "---------------------------------------------"
  # 踏み台用のECSコンテナの開始
  aws ecs update-service \
    --profile default \
    --region ap-northeast-1 \
    --cluster terraform-tutorials-ecs-cluster \
    --service terraform-tutorials-ecs-service \
    --desired-count 1 \
    --no-cli-pager > /dev/null 2>&1
}

#============================================================
# Session ManagerによるRDS接続の開始関数
#============================================================
function start_rds_connection () {
  echo "---------------------------------------------"
  echo "2. Start RDS connection with Session Manager"
  echo "---------------------------------------------"

  # ECSタスクのIDの取得
  while :
  do
    sleep 3
    TASK_ID=`aws ecs list-tasks \
      --profile default \
      --region ap-northeast-1 \
      --cluster terraform-tutorials-ecs-cluster \
      | jq '.taskArns[0]' | sed 's/"//g' | cut -f 3 -d '/'`
    if [ x"$TASK_ID" != x"null" ]; then
      break
    fi
  done
  echo "ECS Container Task ID: $TASK_ID"

  # ECSタスクのラインタイムIDの取得
  while :
  do
    sleep 3
    RUNTIME_ID=`aws ecs describe-tasks \
      --profile default \
      --region ap-northeast-1 \
      --cluster terraform-tutorials-ecs-cluster \
      --task $TASK_ID | jq '.tasks[0].containers[0].runtimeId' | sed 's/"//g'`
    if [ x"$RUNTIME_ID" != x"null" ]; then
      break
    fi
  done
  echo "ECS Runtime ID: $RUNTIME_ID"

  # すぐに繋ぐとエラーとなるため、待機
  sleep 5

  # Session ManagerによるRDS接続の開始
  aws ssm start-session \
    --profile default \
    --region ap-northeast-1 \
    --target "ecs:terraform-tutorials-ecs-cluster_"$TASK_ID"_"$RUNTIME_ID \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters '{"host":["terraform-tutorials-aurora-postgresql.cluster-cewuiyjggrhs.ap-northeast-1.rds.amazonaws.com"],"portNumber":["5432"], "localPortNumber":["5432"]}'
}

#============================================================
# 踏み台用のECSコンテナの終了関数
#============================================================
function stop_container () {
  echo "---------------------------------------------"
  echo "3. Stop bastion container"
  echo "---------------------------------------------"
  # 踏み台用のECSコンテナの停止
  aws ecs update-service \
    --profile default \
    --region ap-northeast-1 \
    --cluster terraform-tutorials-ecs-cluster \
    --service terraform-tutorials-ecs-service \
    --desired-count 0 \
    --no-cli-pager > /dev/null 2>&1
  exit 1
}

#============================================================
# メイン処理
#============================================================

# Ctrl+Cなどで終了したらECSコンテナを終了する処理をトリガー
trap 'stop_container' {1,2,9,20}

# 踏み台用のECSコンテナの開始
start_container

# Session ManagerによるRDS接続の開始
start_rds_connection

# 踏み台用のECSコンテナの終了
stop_container

