def true?(obj)
  obj.to_s.downcase == "true"
end

def escape_double_quote(s)
  s.gsub('"', '\"')
end

def env_var(name, is_bool: false, default: "")
  if is_bool
    ENV.has_key?(name) ? true?(ENV[name]) : true?(default)
  else
    escape_double_quote(ENV.has_key?(name) ? ENV[name] : default)
  end
end

def filter(event)
  require 'time'
  require 'socket'

  msg = event.get("message").gsub("\n", '')

  cw_like = env_var("CLOUDWATCH_LIKE", is_bool: true, default: false)
  if cw_like
    timestamp = Time.now.getutc.to_i.to_s
    msg = escape_double_quote(msg)
    msg = '{"messageType":"DATA_MESSAGE","owner":"' + env_var("CW_OWNER", default: Socket.gethostname) + '","logGroup":"' + env_var("CW_LOGGROUP", default: "syslog") + '","logStream":"' + env_var("CW_LOGSTREAM", default: event.get("host")) + '","logEvents":[{"id":"0","timestamp":' + timestamp + ',"message":"' + msg + '"}]}'
  end

  event.set("newmsg", msg)
  return [event]
end
