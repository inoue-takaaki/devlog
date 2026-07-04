// CloudFront Function（viewer-request）
// ディレクトリ形式のURLを index.html に書き換える。
//   /            -> default_root_object が処理
//   /blog/xxx/   -> /blog/xxx/index.html
//   /blog/xxx    -> /blog/xxx/index.html（拡張子なし）
function handler(event) {
  var request = event.request;
  var uri = request.uri;

  if (uri.endsWith("/")) {
    request.uri += "index.html";
  } else if (!uri.includes(".")) {
    request.uri += "/index.html";
  }

  return request;
}
