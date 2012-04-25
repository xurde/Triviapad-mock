#!/usr/bin/ruby
MOCK_PATH = "#{File.dirname(__FILE__)}/" 

require 'rubygems'
require 'yaml'
require "#{MOCK_PATH}lib/trivia_mock/mock"

MOCKS_FILE = 'mocks.yml'

@mocklist = File.open(MOCKS_FILE) {|yml| YAML::load(yml)}

@mocks = []

@mocklist.each{ |mock|
    puts "[[MAIN]] :: MOCK LAUNCH :: Creating mock id #{mock['name']}"
    new_mock = TriviaMock::Player.new(mock)
    begin
      @thread = Thread.new(new_mock.name){new_mock.play}
    rescue Exception => e
      puts "EXCEPTION IN MAIN THREAD - #{e.message}"
    end
    @mocks << new_mock
    #puts "DEBUG mocks -> #{mocks.map{|r| r.jid}}"
    sleep(1)
}

loop {
  sleep(1)
}