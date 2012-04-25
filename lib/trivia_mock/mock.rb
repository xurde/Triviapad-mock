LIB_PATH = "#{File.dirname(__FILE__)}/../"

require 'xmpp4r'
require 'xmpp4r/muc'
require 'xmpp4r/roster'
require 'xmpp4r/client'

require "#{LIB_PATH}jabber_extend"
require "#{LIB_PATH}logger"


include Jabber
#Jabber::debug = true


MOCKS_HOST = 'dev-guest.triviapad.com'
MUCHOST = "rooms.dev.triviapad.com"
BOTHOST = "dev.triviapad.com"

module TriviaMock
  
  class Player
    
    attr_accessor :botjid, :status
    
    def initialize(config = nil)
      
      #Global Instance variables
      #@nickname = config["nickname"]
      @botid = config["id"]
      @botjid = JID::new("#{@botid}@#{MOCKS_HOST}")
      @botpasswd = config["botpasswd"]
      @roomid = config["roomid"]
      @roomjid = "bot-#{@roomid}@#{BOTHOST}"
      @ratio = config["ratio"].to_f
      @delay = config["delay"].to_f
      
      @logger = EventLogger.new
      @logger.enabled = true
      
      @jclient = Client.new(@botjid)
      @logger.log "Connecting to server as #{@botjid}", :info, "THREAD #{@botid}"
    	@jclient.connect
    	@jclient.auth(@botpasswd)
    	@logger.log "Authenticated!", :info, "THREAD #{@botid}"
    	@status = :connected
    	
      @jclient.send(Presence.new.set_type(:available))
      
      #Fetch rooms
      @logger.log "Fetching rooms...", :info, "THREAD #{@botid}"
      @mucb = MUC::MUCBrowser.new(@jclient)
      rooms = @mucb.muc_rooms(MUCHOST).to_a
      
      # c = 0
      #       for r in rooms
      #         c += 1
      #         puts "#{c} - #{r[1]}"
      #       end
      #puts o = (gets.to_i) - 1 #force to 1
      # o = 0
      # 
      # room_jid = rooms[o][0].node
      # puts "JID -> #{room_jid}"
      
      
      begin #join room and set callbacks
        @muc = MUC::MUCClient.new(@jclient)
        joinroomjid = "#{@roomid}@#{MUCHOST}/#{@botid}"
        @logger.log "Joining Room at #{joinroomjid}...", :info, "THREAD #{@botid} - initialize"
        @muc.join(JID::new(joinroomjid))
        #send_chat('Hi everyone')
        
        # MUC Callbacks
        @muc.add_message_callback do |msg|
          #muc_message_callback(msg)
        end
              
        @muc.add_join_callback do |msg|
          muc_join_callback(msg)
        end
              
        @muc.add_leave_callback do |msg|
          muc_leave_callback(msg)
        end
        
      rescue Exception => e
        @logger.log "Exception while joining #{@roomjid}  --  #{e.message}  --  #{e.backtrace}", :error, "THREAD #{@botid} - initialize"
      else
        @logger.log "Joined #{@roomjid} room successfully!", :info, "THREAD #{@botid} - initialize"
      end
      
      
      @jclient.add_message_callback do |msg|
        @logger.log "#{msg.from}", :message, "THREAD #{@botid} - Message Callback"
        case msg.type
          when :question
            @logger.log "Invocando al azar Quechua... #{msg.inspect}", :question, "THREAD #{@botid}"
            process_question_answer(msg)
          when :ranking
            @logger.log "Processing ranking... #{msg.inspect}", :ranking, "THREAD #{@botid}"
            process_ranking(msg)
          when :chat
            @logger.log "#{msg.from}> ", "Priv Message [#{msg.type}]"
        end
        #send_message(msg.from, "I'm a bot. Leave me alone!")
      end
      
      @jclient.add_presence_callback do |pres|
        begin
          case pres.type
          when :join
            @status = :joined
            @logger.log "#{pres.inspect}", :presence, "THREAD #{@botid} - Presence Callback"
          end
        rescue Exception => e
          @logger.log "Exception #{e.message} - #{e.backtrace}", :presence, "THREAD #{@botid} - Presence Callback"
        end
      end
      
    end #Mock initialized
    
    
    def play
      loop {
        @logger.log "Preparing to join game...", :info, "THREAD #{@botid} - play"
        join_game
        begin #keep playing responding questions
          @status = :playing
          sleep(1)
          #@logger.log "On game loop", :info, "THREAD #{@botid} - play"
        end until @status == :gameover
        @logger.log "Game on room #{@roomjid} is over. Waiting to play again...", :info, "THREAD #{@botid} - play"
        #Pause between games
        sleep (45)
      }
      
    end
    
    def send_chat(msg)
      @muc.send(Jabber::Message.new(@jid, msg))
    end
    
    def send_server(msg)
      jclient.send(msg)
    end
    
    
    def name #Room name
      @name
    end
    
    
    def muc_message_callback(msg)
      @logger.log "#{msg.from} [#{msg.type.to_s}]> #{msg.body}", :info
    rescue Exception => e
      @logger.log "Exception! - #{e.message}", :error, "THREAD #{@botid} - muc message callback"
    end
    
    
    def muc_join_callback(msg)
      @logger.log "#{msg.from} joins the room", :info
    rescue Exception => e
      @logger.log "Exception! - #{e.message}", :error, "THREAD #{@botid} - muc join callback"
    end
    
    def muc_leave_callback(msg)
      @logger.log "#{msg.from} has left the room", :info
    rescue Exception => e
      @logger.log "Exception! - #{e.message}", :error, "THREAD #{@botid} - muc leave callback"
    end
    
    
    
    private
    
      def join_game
        msg = Jabber::Presence.new
        msg.from = @botjid
        msg.to = @roomjid
        msg.type = :join
        msg.id = Time.now.usec.to_s
        msg.add_element 'x', {'xmlns' => 'service/game'}
        
        @logger.log "Preparing Join stanza -> #{msg.inspect}", :presence, "THREAD #{@botid} - join game"
        sleep(3)
        @jclient.send(msg)
        @logger.log "Join stanza Sent", :presence, "THREAD #{@botid} - join game"
        @status = :awaiting
        cont = 0
        begin
          sleep(1)
          cont += 1
          @logger.log "Waiting for join response from #{@roomjid}... (status:#{@status} - cont:#{cont})", :info, "THREAD #{@botid} - join game"
        end until (@status == :joined || cont >= 10)
      rescue Exception => e
        @logger.log "Exception while joining game at #{@roomjid} - #{e.message} - #{e.backtrace}", :error, "THREAD #{@botid} - join game"
      else
        @logger.log "Joined game request at #{@roomjid} successfully sent", :info, "THREAD #{@botid} - join game"
      end
      
      
      def process_question_answer(quest)
        ok_id = quest.first_element("cheat").attribute("id").value.to_i
        begin
          random_id = rand(3) + 1
        end until random_id != ok_id
        
        delay = (rand(10000) * @delay).to_i + 1000
        sleep(delay/1000)
        
        answ = Jabber::Message.new(quest.from)
        answ.type = :answer
        answ.id = quest.id #Same id for responses
        rand_hit = rand(100)/100.0
        hit = (rand_hit <= @ratio)
        @logger.log "HIT :: #{hit.to_s}, #{rand_hit} <= #{@ratio}", :status
        if hit
          answ.add_element 'answer', { 'id' => ok_id , 'time' => delay }
        else
          answ.add_element 'answer', { 'id' => random_id , 'time' => delay }
        end
        @jclient.send(answ)
        @logger.log "Sending Answer response --> #{answ.inspect}", :game
      rescue Exception => e
        @logger.log "Exception while processing answer: #{e.message} ->> #{e.backtrace}", :error, "THREAD #{@botid} - process_question_answer"
      end
      
      
      def process_ranking(ranking)
        type = ranking.first_element("ranking").attribute("type").value
        count = ranking.first_element("ranking").attribute("count").value
        total = ranking.first_element("ranking").attribute("total").value
        
        if type == 'game' && (count == total)
          @status = :gameover
          @logger.log "End of game detected", :game, "THREAD @{botid} - process ranking"
        end
        
        
      rescue Exception => e
        @logger.log "Exception while processing answer: #{e.message} ->> #{e.backtrace}", :error, "THREAD #{@botid} - process_question_answer"
      end
      
      
  end
  
end