##!/usr/bin/env ruby
#
## Enables UTF-8 compatibility in ruby 1.8.
#$KCODE = 'u' if RUBY_VERSION < '1.9'
#
#require 'rubygems'
#
#$:.unshift File.dirname(__FILE__) + "/../lib"
#
#if ARGV.join.match('--debugger')
#  require 'ruby-debug'
#  puts
#  puts "=> Debugger Enabled"
#end
#
#if ARGV.join.match('-c')
#  c = ARGV.join.match(/-c\s*([^\s]+)/)
#  if (c && c[1])
#    ENV['CONFIG_FILE'] = c[1]
#    puts
#    puts "=> Using custom config file #{ENV['CONFIG_FILE'].inspect}"
#  else
#    $stderr.puts("To specify a custom config file use `rubycas-server -c path/to/config_file_name.yml`.")
#    exit
#  end
#end
#
#
#class CASLoginResponse
#  attr_accessor :type, :tgt, :msg
#
#  def initialize(params)
#    attrs = %w(type tgt)
#    attrs.each { |attr| self.instance_variable_set("@#{attr}", params[attr]) }
#    message = params["message"]
#    @msg = message["untranslated_path"]
#  end
#end
#
#require 'rest_client'
#require 'json'
#
#def login(url, payload, headers={}, &block)
#  response_bytes =  RestClient::Request.execute(:method => :post, :url => url, :payload => payload, :headers => headers, &block)
#  JSON.parse(response_bytes)
#end
#
#login_url = 'https://localhost:8888/cas/api-login'
#logout_url = 'https://localhost:8888/cas/api-logout'
#username =  'mani'
#password = 'mani'
#
#response_json = login login_url, :username => username, :password => password
#puts response_json
#response = CASLoginResponse.new(response_json)
#type = response.type
#msg = response.msg
#tgt = response.tgt
#puts "CAS response type is : #{type} and msg is : #{msg} and tgt is : #{tgt}"
#
#response_bytes =  RestClient.delete(logout_url, {:cookies => {:tgt => "#{tgt}"}})
#json = JSON.parse(response_bytes)
#puts json
#message = json["message"]
#return_msg = message["untranslated_path"]
#puts return_msg


# encoding: UTF-8
require File.dirname(__FILE__) + '/spec_helper'
require 'casserver/api'

$LOG = Logger.new(File.basename(__FILE__).gsub('.rb','.log'))

module LoggedInAsUser
  extend RSpec::Core::SharedContext
  before(:each) do
    post '/api-login', { :username => "spec_user", :password => "spec_password"}, "HTTP_ACCEPT" => "application/json"
    last_response.status == 201
    @body = JSON.parse(last_response.body)
  end
end

describe 'Api' do

  def app
    CASServer::APIServer
  end

  before do
    load_server(app)
    reset_spec_database(app)
  end

  describe 'json' do
    include Rack::Test::Methods

    it 'check if cas is alive' do
      get '/api-isalive', {}, "HTTP_ACCEPT" => "application/json"
      last_response.body.should == ""
      last_response.status == 204
    end

    it 'get 404 when use text/html as a http_accept' do
      get '/api-isalive', {}, "HTTP_ACCEPT" => "text/html"
      last_response.status == 404
      get '/api-isalive'
      last_response.status == 404
    end

    it 'get 404 when use diffrent http_accept then json or xml' do
      post '/api-login', { :username => "test", :password => "1233456"}
      last_response.status == 404
    end

    describe 'user is logged' do
      include LoggedInAsUser

      it 'should get tgt' do
        @body["type"].should eq "confirmation"
        @body["tgt"].length.should be > 1
        @body["tgt"].should =~ /TGC\-+\w/
      end

      describe "logout user" do
        it 'should logout' do
          set_cookie "tgt=#{@body['tgt']}"
          delete "/api-logout", {}, "HTTP_ACCEPT" => "application/json"
          body = JSON.parse(last_response.body)
          body["type"].should eq "confirmation"
          last_response.status.should == 200
        end

        it 'should inform that tgt is incorrect and return 203' do
          set_cookie "tgt=1234124124124124"
          delete "/api-logout", {}, "HTTP_ACCEPT" => "application/json"
          body = JSON.parse(last_response.body)
          body["type"].should eq "notice"
          last_response.status.should == 203
        end
      end
    end
  end
end

