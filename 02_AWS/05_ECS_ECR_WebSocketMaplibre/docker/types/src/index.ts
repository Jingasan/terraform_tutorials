// マーカー追加コマンドのデータ型
export type AddMarkerType = {
  id: string; // 端末ID(UUIDv4)
  x: number; // マーカーX座標
  y: number; // マーカーY座標
};

// マーカー削除コマンドのデータ型
export type DeleteMarkerType = {
  id: string; // 端末ID(UUIDv4)
};

// クライアントからサーバーへのコマンド送信イベントの型
export type ClientToServerEvents = {
  addMarker: (data: AddMarkerType) => void;
  deleteMarker: (data: DeleteMarkerType) => void;
};

// サーバーからクライアントへのコマンド送信イベントの型
export type ServerToClientEvents = {
  addMarker: (data: AddMarkerType) => void;
  deleteMarker: (data: DeleteMarkerType) => void;
};
