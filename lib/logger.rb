require 'colored'

class EventLogger
  
  attr_accessor :enabled
  
  #needs optionaly write to logfile
  def initialize
    @enabled = true
    @target = :stdout
  end

  def log(msg, evnt = :general, thread = 'No Thread')
    if @enabled
      text = "[#{thread.upcase}] :: #{evnt.to_s.upcase << ' :: ' if evnt} #{msg}"
      case evnt
      when :info
        puts text.green
      when :status
        puts text.black_on_yellow
      when :game
        puts text.yellow
      when :chat
        puts text.blue
      when :presence
        puts text.magenta
      when :iq
        puts text.cyan
      when :error
        puts text.on_red
      when :general
        puts text.white
      else
        puts text.black_on_white
      end
    end
  end
  
  
end # class
