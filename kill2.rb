#!/usr/bin/env ruby
################################################################################
# ruby >=1.9
#
# This bot requires:
# -- apt-get install ruby ruby-dev
# -- gem install eventmachine
#
# We are all sick of nahums shit, so this bot checks at random intervals to see
# if nahum has been "contributing" to the chat recently.  Upon finding wonton
# nahumism, a retaliatory strike is issued.
#
################################################################################
require 'socket'
require 'openssl'
require 'thread'
require 'eventmachine'

server = 'irc.haxnet.org'
port = '6697'
channel = '#watbot'
nick = 'grundle'

############################################################
# socket connection and irc side commands                  #
############################################################
class IRC
  def initialize(server, port, channel, nick)
    @bot = { :server => server, :port => port, :channel => channel, :nick => nick }
  end

  def connect
    conn = TCPSocket.new(@bot[:server], @bot[:port])
    @socket = OpenSSL::SSL::SSLSocket.new(conn)
    @socket.connect
 
    say "NICK #{@bot[:nick]}"
    say "USER #{@bot[:nick]} 0 * ."

    # this method sucks
    # sleeping 2 seconds to wait for irc connection to fully register me as a user
    sleep 2
    say "JOIN #{@bot[:channel]}"
  end
  
  def say(msg)
    puts msg
    @socket.puts(msg)
  end

  def say_to_chan(msg)
    say "PRIVMSG #{@bot[:channel]} :#{msg}"
  end
  
  def run
    until @socket.eof? do
      msg = @socket.gets
      puts msg
      @history = []
      @history.push( ['timestamp' => Time.now, 'username' => msg.match(/<.(\w+)>/)] )
        
      if msg.match(/^PING :(.*)$/)
        say "PONG #{$~[1]}"
        next
      end
    end
  end
  
  def get_history
    return @history
  end

  def quit(msg = nil)
    #say "PART ##{@channel} :SHIPOOPIE"
    say( msg ? "QUIT #{msg}" : "QUIT" )
    abort("Thank you for playing.")
  end
end

############################################################
# This thread interacts with console user intput           #
# and sends commands/chat to connected irc                 #
############################################################
class ConsoleThread
  def initialize(bot = nil)
    if bot == nil
      puts "We have no bots connected, console input is meaningless"
      exit!
    end

    while(true)
      # capture cli input
      input = gets
      ###########################
      # commands start with /   #
      # everything else is chat #
      ###########################
      case
      # check for irc graceful quit (and maybe a quit message)
      when input.match(/^\/(quit|exit|shutdown|halt|die) (.*)/)
        bot.quit( $~[2] ? $~[2] : nil )
      # private message to user (or other channel)
      when input.match(/^\/msg ([^ ]*) (.*)/)
          bot.say "PRIVMSG #{$~[1]} #{$~[2]}"
      # join new channel command
      when input.match(/^\/join (#.*)/)
          bot.say "JOIN #{$~[1]}"
      # raw irc command (e.g. "JOIN #newchannel")
      when input.match(/^\/raw (.*)/)
          bot.say $~[1]
      # doesnt begin with /, send chat to channel
      else
        bot.say_to_chan(input)
      end
    end
  end
end

############################################################
# you called down the thunder, now reap the whirlwind      #
############################################################
module STF
  def self.is_nahum_alive(irc)
    if irc == nil
      puts "no tcp socket detected"
      exit!
    end

    # get all people seen in the last hour
    recent_chatters = irc.get_history.take_while { |i| i['timestamp'].to_i - (Time.now.to_i - 3600) > 0 }.each { |i| i['username'] }
    if recent_chatters.detect { |i| i == "nahum" }
      return true
    else
      return false
    end
  end
  
  def self.nuke_nahum
    # every pts/xxx he is logged into (includes screen sessions?)
    nahum_terminals = `who | grep nahum`.scan(/nahum\s+(\w+.\w+)/)
    # spawn non-blocking threads of dd /dev/urandom at each terminal currently connected
    nahum_terminals.each { |term| spawn 'dd if=/dev/urandom of=/dev/#{term} bs=10M count=1' }
  end
end

########
# Main #
########
# initialize our irc bot
irc = IRC.new(server, port, channel, nick) 

# trap ^C signal from keyboard and gracefully shutdown the bot
# quit messages are only heard by IRCD's if you have been connected long enough(!)
trap("INT"){ irc.quit("fucking off..") }

# spawn console input handling thread
console = Thread.new{ ConsoleThread.new(irc) }

# connect to irc server (and join channel?!?)
irc.connect
# run main irc bot execution loop (ping/pong, communication etc)
irc_thread = Thread.new{ irc.run }
# this locks until irc.run is finished, but we now see incoming irc traffic in terminal
irc_thread.join   

puts 'this wont appear'
