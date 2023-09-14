import React from "react";
import { io, Socket } from "socket.io-client";
import maplibregl from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";
import { v4 as uuidv4 } from "uuid";
import {
  AddMarkerType,
  DeleteMarkerType,
  ClientToServerEvents,
  ServerToClientEvents,
} from "@socketio_maplibre/types";
import "./App.css";

// WebSocketサーバーの接続設定
// const HOST = "localhost"
// const PORT = 80;
const socket: Socket<ClientToServerEvents, ServerToClientEvents> = io(
  window.location.href
  // "http://" + HOST + ":" + PORT
);
// MapLibreのMapオブジェクト
let map: maplibregl.Map;
// Markerを格納する配列
let markers: maplibregl.Marker[] = [];
// 端末識別の為のuuid
const uuid = uuidv4();

// メッセージアプリのコンポーネント
export default function App() {
  const mapContainer = React.useRef<HTMLDivElement | null>(null);

  React.useEffect(() => {
    // WebSocket接続
    socket.connect();

    // WebSocketの接続開始時
    const onConnect = () => {
      console.log("WebSocket is connected.");
    };
    socket.on("connect", onConnect);

    // サーバーからのマーカー追加コマンド受信時の処理を登録
    const onAddMarker = (data: AddMarkerType) => {
      let color = "#5AFF19"; // 他者がセットしたマーカーの場合は緑マーカーとする
      if (data.id === uuid) color = "#FF0000"; // 自身がセットしたマーカーの場合は赤マーカーとする
      let marker = new maplibregl.Marker({ color: color })
        .setLngLat([data.x, data.y])
        .addTo(map);
      markers.push(marker);
    };
    socket.on("addMarker", onAddMarker);

    // サーバーからのマーカー削除コマンド受信時の処理を登録
    const onDeleteMarker = (data: DeleteMarkerType) => {
      if (markers.length === 0) return;
      markers[markers.length - 1].remove();
      markers.pop();
    };
    socket.on("deleteMarker", onDeleteMarker);

    // WebSocketの接続切断時
    const onDisconnect = () => {
      console.log("WebSocket is disconnected.");
    };
    socket.on("disconnect", onDisconnect);

    // Clean up
    return () => {
      console.log("Unmounted");
      // イベントリスナーの解除
      socket.off("addMarker", onAddMarker);
      socket.off("deleteMarker", onDeleteMarker);
      socket.off("connect", onConnect);
      socket.off("disconnect", onDisconnect);
      // WebSocketの切断
      socket.disconnect();
    };
  }, []);

  // マーカー追加処理(Publish)
  const addMarker = (x: number, y: number) => {
    // Publishを行うと、購読(Subscribe)しているため、上記のonAddMarkerの処理が走る
    const marker: AddMarkerType = {
      id: uuid,
      x: x,
      y: y,
    };
    // マーカー追加コマンドをサーバーに送信
    socket.emit("addMarker", marker);
  };

  // マーカー削除処理(Publish)
  const deleteButtonClick = () => {
    // Publishを行うと、購読(Subscribe)しているため、上記のonDeleteMarkerの処理が走る
    const marker: DeleteMarkerType = {
      id: uuid,
    };
    // マーカー削除コマンドをサーバーに送信
    socket.emit("deleteMarker", marker);
  };

  // 初期化
  React.useEffect(() => {
    if (!map) {
      if (!mapContainer.current) return;
      // 地図の作成
      map = new maplibregl.Map({
        container: mapContainer.current,
        style:
          "https://gsi-cyberjapan.github.io/gsivectortile-mapbox-gl-js/std.json", // 地図のスタイル(国土地理院地図のMapboxVectorTileを指定)
        center: [139.753, 35.6844], // 初期緯度経度
        zoom: 7, // 初期ズーム値
        minZoom: 4, // 最小ズーム値
        maxZoom: 16, // 最大ズーム値
      });
      map.addControl(new maplibregl.NavigationControl({}), "top-right"); // ズーム・回転コントロールの表示
      map.addControl(new maplibregl.ScaleControl({}), "bottom-left"); // スケール値の表示
      map.showTileBoundaries = true; // タイル境界線の表示
      // 地図上のクリックしたとき
      map.on("click", (e) => {
        // クリックした地点にマーカーを追加
        const [x, y] = e.lngLat.toArray();
        console.log([x, y]);
        addMarker(x, y);
      });
    }
  });

  // 地図の表示
  return (
    <>
      <button className="button" onClick={deleteButtonClick}>
        Delete Marker
      </button>
      <div ref={mapContainer} className="map" />
    </>
  );
}
