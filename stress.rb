#!/usr/bin/ruby
require 'rubygems'

MOCK_PATH = "#{File.dirname(__FILE__)}/"
require "#{MOCK_PATH}lib/trivia_mock/mock"

MOCKS_NUM = 10
PAUSE = 1

@mocks = []

def show_status
  puts "[[MOCKS STATUS]]"
  puts "Mocks Running: #{@mocks.size}"
  puts "By status :: All: #{@mocks.size} - playing: #{@mocks.select{|i| i.status == :playing }.size} - gameover: #{@mocks.select{|i| i.status == :gameover }.size}}"  
end


for i in 1..MOCKS_NUM
  puts "[[MAIN]] :: MOCK LAUNCH :: Starting loop ##{i}"
  
  mock = {}
  mock['name'] = "Mock #{i}"
  mock['botjid'] = "mock-#{i}"
  mock['botpasswd'] = "123456"
  #mock['roomid'] = "dev-room"
  mock['roomid'] = "quickie"
  mock['ratio'] = 0.5
  mock['delay'] = 0.5
  
  begin
    puts "[[MAIN]] :: MOCK LAUNCH :: Creating threaded mock id #{mock['botjid']}"
    @thread = Thread.new(mock['roomid']) do
      @new_mock = TriviaMock::Player.new(mock)
      @mocks << @new_mock
      puts "[[MAIN]] :: MOCK LAUNCH :: Created mock -> #{@new_mock.botjid} Status: #{@new_mock.status}}"
      @new_mock.play
    end
  rescue Exception => e
    puts "EXCEPTION IN MAIN THREAD - #{e.message}"
  end
  show_status
  sleep(PAUSE)
end



loop {
  sleep(1)
  show_status
}