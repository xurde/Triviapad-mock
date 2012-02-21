#!/usr/bin/ruby

require 'rubygems'
require 'lib/trivia_mock/mock'

MOCKS_NUM = 100
PAUSE = 0.2

@mocks = []


for i in 1..MOCKS_NUM
  puts "[[MAIN]] :: MOCK LAUNCH :: Creating mock id #{i}"
  
  mock = {}
  mock['name'] = "Mock #{i}"
  mock['botjid'] = "mock-#{i}"
  mock['botpasswd'] = "123456"
  mock['roomid'] = "trivianerds"
  mock['ratio'] = 0.5
  mock['delay'] = 0.5
  
  puts "[[MAIN]] :: MOCK LAUNCH :: Creating mock id #{mock['botjid']}"
  new_mock = TriviaMock::Player.new(mock)
  begin
    @thread = Thread.new(new_mock.name){new_mock.play}
    puts "[[MAIN]] :: MOCK LAUNCH :: Done!"
  rescue Exception => e
    puts "EXCEPTION IN MAIN THREAD - #{e.message}"
  end
  @mocks << new_mock
  puts "[[MOCKS STATUS]]"
  @mocks.each{|m| puts "#{m.botjid} (#{m.status})"}
  sleep(PAUSE)
  puts "[[MAIN]] :: MOCK LAUNCH :: Creating mock id #{new_mock.botjid}"
end

loop {
  sleep(1)
  puts "Sleeping..."
}