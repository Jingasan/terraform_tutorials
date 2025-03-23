/**
 * AWS Backupの古いをリカバリーポイントを削除する定期実行Lambda
 */
import * as Backup from "@aws-sdk/client-backup";
import { ScheduledHandler, ScheduledEvent } from "aws-lambda";
import { Logger } from "@aws-lambda-powertools/logger";
const REGION = process.env.REGION || "ap-northeast-1";
const VAULT_NAME = process.env.VAULT_NAME;
const logger = new Logger();
const client = new Backup.BackupClient({ region: REGION });

/**
 * Vaultに保存されたリカバリーポイント一覧の取得
 * @param backupVaultName ターゲットのVault名
 * @returns Vaultに保存されたリカバリーポイントの一覧
 */
const getRecoveryPointList = async (
  backupVaultName: string
): Promise<Backup.RecoveryPointByBackupVault[]> => {
  let recoveryPoints: Backup.RecoveryPointByBackupVault[] = [];
  let nextToken: string | undefined = undefined;
  try {
    do {
      const command = new Backup.ListRecoveryPointsByBackupVaultCommand({
        BackupVaultName: backupVaultName,
        NextToken: nextToken,
      });
      const res = await client.send(command);
      if (res.RecoveryPoints) {
        recoveryPoints = recoveryPoints.concat(res.RecoveryPoints);
      }
      nextToken = res.NextToken; // 次のページのトークンを取得
    } while (nextToken); // nextTokenがある限りループ
    return recoveryPoints;
  } catch (e) {
    logger.error(e);
    return [];
  }
};

/**
 * Vaultから指定のリカバリーポイントを削除
 * @param deleteTargetRecoveryPointARN 削除対象のリカバリーポイントのARN
 * @returns true:成功
 */
const deleteRecoveryPoint = async (deleteTargetRecoveryPointARN: string) => {
  try {
    const command = new Backup.DeleteRecoveryPointCommand({
      BackupVaultName: VAULT_NAME,
      RecoveryPointArn: deleteTargetRecoveryPointARN,
    });
    await client.send(command);
    return true;
  } catch (e) {
    logger.error(e);
    return false;
  }
};

/**
 * 定刻にVaultから最新のバックアップを１つ残して古いバックアップをすべて削除するハンドラ
 * @param event イベント
 * @returns イベント
 */
export const handler: ScheduledHandler = async (event: ScheduledEvent) => {
  // リカバリーポイントの一覧取得
  const recoveryPointList = await getRecoveryPointList(VAULT_NAME);
  if (!recoveryPointList.length) {
    logger.info("No recovery points found.");
    return;
  }

  // リカバリーポイントの一覧を作成日時順にソート
  const sortedRecoveryPoints = recoveryPointList.sort(
    (a, b) =>
      (b.CreationDate?.getTime() ?? 0) - (a.CreationDate?.getTime() ?? 0)
  );

  // ステータスがCOMPLETEDである最新のリカバリーポイントのインデックスを取得
  let latestCompletedIdx = 0;
  for (let i = 0; i < sortedRecoveryPoints.length; i++) {
    if (
      sortedRecoveryPoints[i].Status === Backup.RecoveryPointStatus.COMPLETED
    ) {
      latestCompletedIdx = i;
      break; // 最初の "COMPLETED" を見つけたらループ終了
    }
  }

  // ステータスがCOMPLETEDである最新のリカバリーポイント情報
  logger.info(
    `[Newest recovery point info]
idx: ${latestCompletedIdx}
RecoveryPointARN: ${sortedRecoveryPoints[latestCompletedIdx].RecoveryPointArn}
CreationDate: ${sortedRecoveryPoints[latestCompletedIdx].CreationDate}
Status: ${sortedRecoveryPoints[latestCompletedIdx].Status}
StatusMessage: ${sortedRecoveryPoints[latestCompletedIdx].StatusMessage}
BackupSize(Bytes): ${sortedRecoveryPoints[latestCompletedIdx].BackupSizeInBytes}
ResourceType: ${sortedRecoveryPoints[latestCompletedIdx].ResourceType}
ResourceName: ${sortedRecoveryPoints[latestCompletedIdx].ResourceName}
`
  );

  // 残るリカバリーポイントの数
  const toKeep = sortedRecoveryPoints.slice(0, latestCompletedIdx + 1);
  if (toKeep.length >= 3) {
    logger.info("Maybe some NotCompleted recovery points are existed.");
  }

  // ステータスがCOMPLETEDである最新のリカバリーポイントまでを残し、それ以前の古いリカバリーポイントは削除
  const toDelete = sortedRecoveryPoints.slice(latestCompletedIdx + 1);
  logger.info("Deleting old recovery points...");
  if (toDelete.length > 0) {
    await Promise.allSettled(
      toDelete.map(async (recoveryPoint) => {
        if (recoveryPoint.RecoveryPointArn) {
          const res = await deleteRecoveryPoint(recoveryPoint.RecoveryPointArn);
          if (res) {
            logger.info(
              `Succeeded to delete old recovery point: ${recoveryPoint.RecoveryPointArn}`
            );
          } else {
            logger.error(
              `Failed to delete old recovery point: ${recoveryPoint.RecoveryPointArn}`
            );
          }
        }
      })
    );
  } else {
    logger.info("No recovery points to delete.");
  }
  logger.info("Finished to delete old recovery points.");
};
