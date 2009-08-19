
$:.unshift File.dirname(__FILE__) 

require 'webrick'
require 'thread'
require 'browsers'
require 'servlets'

module JSpec
  class Server
    
    ##
    # Suite HTML.
    
    attr_accessor :suite
    
    ##
    # Host string.
    
    attr_reader :host
    
    ##
    # Port number.
    
    attr_reader :port
    
    ##
    # Server instance.
    
    attr_reader :server
    
    ##
    # Initialize.
    
    def initialize suite, host, port
      @suite, @host, @port = suite, host, port
    end
    
    ##
    # Uri.
    
    def uri
      'http://%s:%d' % [host, port]
    end
    
    ##
    # Start the server with _browsers_ which defaults to all supported browsers.
    
    def start browsers = nil
      browsers ||= Browser.subclasses.map{ |b| b.new }
      @server = WEBrick::HTTPServer.new :Port => port, :Host => host, :DocumentRoot => Dir.pwd
      trap('INT') { shutdown }
      mount_servlets_to server
      thread = Thread.new { server.start }
      browsers.each do |browser|
        if browser.supported?
          browser.setup
          say "Started testing in #{browser}"
          browser.visit uri + '/' + suite
          browser.teardown
        end
      end
      say "Starting server at #{uri}"
      server.shutdown
      thread.join
    end
    
    ##
    # Mount all servlets extending JSpec::Servlet to _server_.
    
    def mount_servlets_to server
      Servlet.subclasses.each do |servlet|
        server.mount *servlet.mount
      end
    end
    
    ##
    # Shutdown.
    
    def shutdown
      say "\nShutting down server"
      server.shutdown
      exit 1
    end
    
  end
end