import { randomUUID } from "crypto";
import * as Batch from "@google-cloud/batch";

export class BatchClient {
  private batchClient = new Batch.BatchServiceClient();

  /**
   * ジョブの作成
   * @param projectId プロジェクトID
   * @param region リージョン
   * @param jobId ジョブID
   * @returns ジョブ名/false:失敗
   */
  public createJob = async (
    projectId: string,
    region: string
  ): Promise<string | false> => {
    try {
      const [res] = await this.batchClient.createJob({
        parent: `projects/${projectId}/locations/${region}`,
        jobId: `job-${randomUUID()}`,
        job: {
          taskGroups: [
            {
              taskSpec: {
                runnables: [
                  {
                    displayName: "1",
                    container: {
                      imageUri: "hello-world:latest",
                      blockExternalNetwork: false,
                      commands: [],
                      entrypoint: "",
                      volumes: [],
                    },
                    timeout: { seconds: 3600 },
                    background: false,
                    alwaysRun: false,
                    ignoreExitStatus: false,
                    labels: {},
                  },
                  {
                    displayName: "2",
                    container: {
                      imageUri: "hello-world:latest",
                      blockExternalNetwork: false,
                      commands: [],
                      entrypoint: "",
                      volumes: [],
                    },
                    timeout: { seconds: 3600 },
                    background: false,
                    alwaysRun: false,
                    ignoreExitStatus: false,
                    labels: {},
                  },
                ],
                environments: {},
                computeResource: {
                  cpuMilli: "1000",
                  memoryMib: "512",
                  bootDiskMib: "0",
                },
                lifecyclePolicies: [],
                maxRetryCount: 0,
              },
              taskCount: "1",
              parallelism: "1",
              schedulingPolicy: "SCHEDULING_POLICY_UNSPECIFIED",
              taskCountPerNode: "0",
              requireHostsFile: false,
              permissiveSsh: false,
            },
          ],
          logsPolicy: {
            destination: "CLOUD_LOGGING",
          },
          labels: {},
        },
      });
      return res.name;
    } catch (err) {
      console.error(err);
      return false;
    }
  };

  /**
   * ジョブ一覧の取得
   * @param projectId プロジェクトID
   * @param region リージョン
   * @returns ジョブ一覧
   */
  public listJobs = async (
    projectId: string,
    region: string
  ): Promise<string[]> => {
    try {
      const list: string[] = [];
      const iterable = this.batchClient.listJobsAsync({
        parent: `projects/${projectId}/locations/${region}`,
      });
      for await (const response of iterable) {
        list.push(response.name);
      }
      return list;
    } catch (err) {
      console.error(err);
      return [];
    }
  };

  /**
   * ジョブ情報の取得
   * @param jobId ジョブID
   * @returns ジョブ情報
   */
  public getJobInfo = async (jobId: string): Promise<any> => {
    try {
      const [response] = await this.batchClient.getJob({
        name: jobId,
      });
      return response;
    } catch (err) {
      console.error(err);
      return {};
    }
  };

  /**
   * ジョブの削除
   * @param jobId 削除対象のジョブID
   * @returns true:成功/false:失敗
   */
  public deleteJob = async (jobId: string): Promise<boolean> => {
    try {
      await this.batchClient.deleteJob({
        name: jobId,
      });
      return true;
    } catch (err) {
      console.error(err);
      return false;
    }
  };
}
