import * as esbuild from "esbuild";
import dependencies from "./package.json";

// ES Modules/CommonJSで共通のビルド設定
const buildSetting = {
  entryPoints: ["src/index.ts"], // エントリポイント
  bundle: true, // バンドルする（ビルド成果物をまとめる）かどうか
  minify: true, // コードを最小化するかどうか
  sourcemap: false, // SourceMapを出力するかどうか
  external: Object.keys(dependencies),
  // バンドルに含めるべきでない外部パッケージの指定
  // esbuildはデフォルトではすべての依存関係を含めてバンドルするが、
  // 外部パッケージをバンドルに含めると、サイズが不必要に大きくなる。
  // externalオプションでは、バンドルに含めない外部パッケージを指定し、
  // バンドルに含めず、外部から読み込むことを前提とする。
};

// ES Modules向けのビルド
esbuild.build({
  format: "esm", // 出力フォーマットの指定(デフォルト：iife)
  // cjs: CommonJSモジュールとして出力する（Node.js向け）
  // esm: ECMAScriptモジュールとして出力する（Node.js向け）
  // iife: 即時関数として出力する（ブラウザ向け）
  // esm-browser: ブラウザ用のECMAScriptモジュールとして出力する（ブラウザ向け）
  target: ["ES6"], // 出力するJSのバージョンや実行環境の指定
  // 指定しない場合はesbuildが自動的に実行環境に応じたコードに変換する。
  // esnext: 最新のECMAScriptの仕様に準拠したコードを生成
  // es2022, ..., es2015(ES6): ECMAScriptのバージョンの指定
  // nodeXX.X: Node.jsのバージョンの指定
  // chromeXX, firefoxXX, safariXX, edgeXX: ブラウザバージョンの指定
  outfile: "./dist/index.esm.js", // 出力ビルドファイル名
  entryPoints: buildSetting.entryPoints,
  external: buildSetting.external,
  bundle: buildSetting.bundle,
  minify: buildSetting.minify,
  sourcemap: buildSetting.sourcemap,
});

// CommonJS向けのビルド
esbuild.build({
  format: "cjs",
  target: ["ES6"], // 出力するJSのバージョンや実行環境の指定
  // ECMAScript 2015 (ES6)に準拠
  outfile: "./dist/index.cjs.js", // 出力ビルドファイル名
  entryPoints: buildSetting.entryPoints,
  external: buildSetting.external,
  bundle: buildSetting.bundle,
  minify: buildSetting.minify,
  sourcemap: buildSetting.sourcemap,
});
