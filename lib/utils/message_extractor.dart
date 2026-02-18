String extractMessage(dynamic res) {
  if (res == null) return "";
  if (res["message"] != null) return res["message"];
  if (res["content"] != null) return res["content"];
  if (res["text"] != null) return res["text"];
  if (res["output"] != null) return res["output"];
  if (res["data"]?["content"] != null) return res["data"]["content"];
  return "";
}
