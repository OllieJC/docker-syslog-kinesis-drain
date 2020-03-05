def filter(event)
  #require 'base64';
  #require 'zlib';
  msg = event.get("message").gsub("\n", '').gsub('"', '\"')
  t = '{"messageType":"DATA_MESSAGE","owner":"0","logGroup":"syslog","logStream":"-","logEvents":[{"message":"' + msg + '"}]}'
  #b = Zlib.gzip(t).delete!("\n")
  event.set("newmsg", t)
  #event.set("rand", rand(36**10).to_s(36))
  return [event]
end
