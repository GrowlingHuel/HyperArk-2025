# Simple fix: just add decode_body: false to the Req.get call
content = File.read!("lib/green_man_tavern/mindsdb/http_client.ex")

# Replace the Req.get line in get_status function
fixed_content =
  String.replace(
    content,
    "case Req.get(url: url, receive_timeout: 10_000) do",
    "case Req.get(url: url, receive_timeout: 10_000, decode_body: false) do"
  )

File.write!("lib/green_man_tavern/mindsdb/http_client.ex", fixed_content)
