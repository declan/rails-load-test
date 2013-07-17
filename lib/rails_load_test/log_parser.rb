class LogParser

  attr_reader :num_get_requests, :num_post_requests

  def initialize(log_name, options = {})
    @log_name = log_name
    @outfile = options[:outfile] || STDOUT
    @sessions = {}
    @password = options[:password]
    @num_get_requests = 0
    @num_post_requests = 0
  end

  def parse
    fd = File.open(@log_name, "r")
    begin
      while (request = parse_request(fd)) do
        push_request(request)
      end
      print_sessions
    rescue
      print_summary(STDERR)
    ensure
      fd.close
    end
  end

  def parse_request(file_descriptor)
    # read to the next GET, POST, PUT, or DELETE
    return nil unless line = file_descriptor.gets

    if http_verb = log_regexps[:http_verb].match(line)
      send("parse_#{http_verb.to_s.downcase}_request", line, file_descriptor)
    else
      parse_request(file_descriptor)
    end
  end

  def parse_get_request(line, file_descriptor)
    matches = log_regexps[:get].match(line)
    STDERR.puts "could not parse line \"#{line}\"" if matches.nil?
    request = Request.new(matches.captures[1], matches.captures[0])
    @num_get_requests += 1
    request
  end

  def parse_post_request(line, file_descriptor)
    _parse_request_helper(line, file_descriptor, :post)
  end

  def parse_delete_request(line, file_descriptor)
    _parse_request_helper(line, file_descriptor, :delete)
  end

  def parse_put_request(line, file_descriptor)
    _parse_request_helper(line, file_descriptor, :put)
  end

  def _parse_request_helper(line, file_descriptor, method)
    matches = log_regexps[method].match(line)
    STDERR.puts "could not parse line \"#{line}\"" if matches.nil?
    params_hash = parse_params(file_descriptor)
    params_hash["_method"] = method.to_s unless method == :post
    content = matches.captures[0] + ' method=POST contents="' + params_hash_to_httperf(params_hash) + '"'
    request = Request.new(matches.captures[1], content)
    @num_post_requests += 1
    request
  end

  def parse_params(file_descriptor)
    params_str = get_params(file_descriptor)
    params_hash = StrToHash.parse(params_str)
    if params_hash.nil?
      STDERR.puts "StrToHash failed to parse \"#{params_str}\""
      {}
    else
      params_hash
    end
  end

  def get_params(file_descriptor)
    while line = file_descriptor.gets do
      if matches = /^  Parameters: (.*)$/.match(line)
        return matches.captures[0]
      end
    end
    nil
  end

  def params_hash_to_httperf(hash, prefix = '')
    if @password && hash["password"]
      hash["password"] = @password
    end
    hash.delete("utf8")
    hash.delete("authenticity_token")
    hash.collect do |key, val|
      if val.kind_of?(Hash)
        params_hash_to_httperf(val, full_key(prefix, key))
      else
        CGI.escape(full_key(prefix, key)) + '=' + CGI.escape(val)
      end
    end.compact.join('&')
  end

  def full_key(prefix, key)
    if prefix == ''
      key
    else
      prefix + '[' + key + ']'
    end
  end

  def print_sessions
    @sessions.each_with_index do |requests, i|
      requests[1].each do |request|
        @outfile.write(request + "\n")
      end
      @outfile.write("\n") unless i == (@sessions.length - 1)
    end
  end

  def push_request(request)
    @sessions[request.ip] ||= []
    @sessions[request.ip].push(request.path)
  end

  def log_regexps
    ip_addr = /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
    url = /[\[\]\.+&%\/\w\?=\-]*/
    {
      :http_verb => /(GET|POST|PUT|DELETE)/,
      :get => /Started GET "(#{url})" for (#{ip_addr}) at/,
      :post => /Started POST "(#{url})" for (#{ip_addr}) at/,
      :put => /Started PUT "(#{url})" for (#{ip_addr}) at/,
      :delete => /Started DELETE "(#{url})" for (#{ip_addr}) at/
    }
  end

  def print_summary(file_descriptor)
    file_descriptor.write("# Parsed #{num_requests_parsed} requests from #{num_ip_addresses_parsed} ip addresses.\n")
    file_descriptor.write("# #{num_get_requests} GET requests and #{num_post_requests} POST requests.\n")
  end

  def num_requests_parsed
    @sessions.values.flatten.length
  end

  def num_ip_addresses_parsed
    @sessions.length
  end


  Request = Struct.new(:ip, :path)

end
