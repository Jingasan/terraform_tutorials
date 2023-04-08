import express from "express";
import * as http from "http";
import * as socketio from "socket.io";
import {
  ClientToServerEvents,
  ServerToClientEvents,
} from "@socketio_maplibre/types";

// WebSocketサーバーの設定
const PORT = 80;

// 初期化
const app: express.Express = express();
const server = http.createServer(app);
const io = new socketio.Server<ClientToServerEvents, ServerToClientEvents>(
  server,
  {
    cors: {
      origin: "*", // クロスサイトの許容
      credentials: true,
    },
  }
);

// 静的ファイルを返す処理
app.use(express.static("public"));

// WebSocket接続数
let connectionNum = 0;

// WebSocketサーバーの起動
server.listen(PORT, () => {
  console.log("Server running at localhost:" + PORT);
  console.log("connection num: " + connectionNum);
});

// 接続確立時
io.on("connection", (socket) => {
  connectionNum++;
  console.log("connection num: " + connectionNum);

  // クライアントからのマーカー追加コマンド受信時
  socket.on("addMarker", (data) => {
    console.log(
      "Receive addMarker command from " +
        data.id +
        ": (" +
        data.x +
        ", " +
        data.y +
        ")"
    );
    // 全クライアントへのマーカー追加コマンド送信
    io.emit("addMarker", data);
  });
  // クライアントからのマーカー削除コマンド受信時
  socket.on("deleteMarker", (data) => {
    console.log("Receive deleteMarker command from " + data.id);
    // 全クライアントへのマーカー削除コマンド送信
    io.emit("deleteMarker", data);
  });

  // 接続終了時
  socket.on("disconnect", () => {
    connectionNum--;
    console.log("connection num: " + connectionNum);
  });
});
