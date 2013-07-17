require 'spec_helper'

describe LogParser do
  let(:outfile) { double(:class => IO) }
  let(:request) { LogParser::Request.new('192.168.16.666', '/goodnight-moon.cfs') }
  let(:parser) { LogParser.new("spec/fixtures/test.log", :outfile => outfile) }

  describe "#parse" do
    it "writes to the provided outfile" do
      outfile.should_receive(:write)
      parser.parse
    end

    it "writes to stdout by default" do
      p = LogParser.new("spec/fixtures/test.log")
      STDOUT.should_receive(:write)
      p.parse
    end
  end

  it '#print_summary(file_descriptor)' do
    parser = LogParser.new("spec/fixtures/get_and_post_and_blacklisted_requests.log")
    parser.parse
    outfile.should_receive(:write).with("# Parsed 5 requests from 3 ip addresses.\n")
    outfile.should_receive(:write).with("# 3 GET requests and 2 POST requests.\n")
    parser.print_summary(outfile)
  end

  describe "#parse_request(file_descriptor)" do
    # Refer to spec/fixtures/*.log to understand these specs.
    it "parses GET requests" do
      fd = File.open("spec/fixtures/get_requests.log", "r")
      request = parser.parse_request(fd)
      request.path.should == '/api/programs?page=1'
    end

    it "parses complex GET requests" do
      fd = File.open("spec/fixtures/get_with_params.log", "r")
      request = parser.parse_request(fd)
      request.path.should == '/explore?utf8=%E2%9C%93&search%5Bwhat%5D=counseling+and+therapy&search%5Bwhere%5D=dolton+IL&commit=Search'
    end

    it "parses GET requests with []'s" do
      fd = File.open("spec/fixtures/get_with_params.log", "r")
      parser.parse_request(fd)  # throw away the first line
      request = parser.parse_request(fd)
      request.path.should == '/explore?utf8=%E2%9C%93&search[what]=&search[where]=hyde+park&commit=Search&kme=Visit%20From%20Drip%20Email&km_email_number=1'
    end

    it "parses POST requests" do
      fd = File.open("spec/fixtures/post_requests.log", "r")
      request = parser.parse_request(fd)
      request.path.should == '/binders method=POST contents="binder%5Bname%5D=CF+Binder"'
    end

    it "parses PUT requests" do
      fd = File.open("spec/fixtures/put_requests.log", "r")
      request = parser.parse_request(fd)
      request.path.should == '/profile/update_terms method=POST contents="_method=put"'
    end

    it "parses DELETE requests" do
      fd = File.open("spec/fixtures/delete_requests.log", "r")
      request = parser.parse_request(fd)
      request.path.should == '/programs/tumbling-4-success/locations/6144 method=POST contents="program_id=tumbling-4-success&id=6144&_method=delete"'
    end

  end

  describe '#parse_params' do
    it "returns an empty hash if there are no params" do
      fd = File.open("spec/fixtures/no_params.log", "r")
      parser.parse_params(fd).should == {}
    end

    it "returns an empty hash if the params were malformed" do
      fd = File.open("spec/fixtures/malformed_params.log", "r")
      parser.parse_params(fd).should == {}
    end
  end

  describe '#get_params(file_descriptor)' do
    it "reads the params in from the file" do
      fd = File.open("spec/fixtures/simple_params.log", "r")
      parser.get_params(fd).should == '{"page"=>"1"}'
    end

    it "returns nil if there are no params in the file" do
      fd = File.open("spec/fixtures/no_params.log", "r")
      parser.get_params(fd).should == nil
    end

    it "ignores lines that don't contain params" do
      fd = File.open("spec/fixtures/params_at_bottom.log", "r")
      parser.get_params(fd).should_not == nil
    end
  end

  describe '#params_hash_to_httperf' do
    {
      {'foo' => 'bar'} => 'foo=bar',
      {'foo' => {'bar' => 'baz'}} => 'foo%5Bbar%5D=baz',
      {'foo' => 'schmoo', 'wee' => 'zee', 'hello' => 'kitty'} => 'foo=schmoo&wee=zee&hello=kitty',
      {'foo' => {'bar' => 'baz', 'bee'=>'bop'}} => 'foo%5Bbar%5D=baz&foo%5Bbee%5D=bop',
      {'foo' => 'hello kitty'} => 'foo=hello+kitty',
      # Don't record authenticity token.
      {'foo' => 'bar', 'authenticity_token' => 'gOB3ldyG0O|<'} => 'foo=bar',
      # Don't record UTF-8.
      {'foo' => 'bar', 'utf8' => '\u2713'} => 'foo=bar',
      {'email' => 'bob@purplebinder.com'} => 'email=bob%40purplebinder.com',
      {'dataset_ids' => ['', '3']} => 'dataset_ids=3'  # TODO look up the actual params encoding of this.
    }.each do |key, val|
      it key do
        parser.params_hash_to_httperf(key).should == val
      end
    end

    it "lets you specify a password" do
      parser = LogParser.new("spec/fixtures/test.log", :password => 'purpleotter')
      parser.params_hash_to_httperf({'password'=>'[FILTERED]'}).should == "password=purpleotter"
    end
  end

  describe "#push_request" do
    let(:request) { LogParser::Request.new("127.0.0.1", "/hello-world.cfs") }
    it "pushes into the sessions array" do
      parser.push_request(request)
      parser.instance_variable_get(:@sessions).length.should == 1
    end
  end

  describe "#print_sessions" do
    it "prints all requests for each session, sessions separated by blank lines" do
      parser.push_request(LogParser::Request.new("127.0.0.1", "/goodnight-moon.cfs"))
      parser.push_request(LogParser::Request.new("127.0.0.1", "/goodnight-mush.cfs"))
      parser.push_request(LogParser::Request.new("192.11.10.591", "/aardvarks-anonymous.jsp"))
      outfile.should_receive(:write).with("/goodnight-moon.cfs\n")
      outfile.should_receive(:write).with("/goodnight-mush.cfs\n")
      outfile.should_receive(:write).with("\n")  # separate sessions with a blank line
      outfile.should_receive(:write).with("/aardvarks-anonymous.jsp\n")
      parser.print_sessions
    end
  end
end
