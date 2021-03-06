#
# Copyright (c) 2018 ITO SOFT DESIGN Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

<<-DOC
Here is a sample configuration.
Puts your configuration to config/plugins/trello.yml

consummer_key: your_consumer_key
consumer_secret: your_consumer_secret
oauth_token: your_oauth_token

events:
  - trigger:
      device: D0
      type: changed
      value_type: text
      text_length: 8
    board_name: 工程モニター
    list_name: 工程1
    title: __value__
  - trigger:
      device: D10
      type: changed
      value_type: text
      text_length: 8
    board_name: 工程モニター
    list_name: 工程2
    title: __value__
DOC

require 'net/https'
require 'trello'

# @see https://qiita.com/tbpgr/items/60fc13aca8afd153e37b


module LadderDrive
module Emulator

class TrelloPlugin < Plugin

  def initialize plc
    super #plc
    return if disabled?

    @values = {}
    @times = {}
    @worker_queue = Queue.new

    @configured = Trello.configure do |config|
      config.consumer_key = self.config[:consumer_key]
      config.consumer_secret = self.config[:consumer_secret]
      config.oauth_token = self.config[:oauth_token]
    end
    setup
  end

  def run_cycle plc
    return if disabled?
    return if config[:events].nil?

    @config[:events].each do |event|
      begin
        next unless self.triggered?(event)

        device = trigger_state_for(event).device
        v = trigger_state_for(event).value
        @worker_queue.push event:event, device_name:device.name, value:v, time: Time.now

      rescue => e
        p e
puts $!
puts $@
      end
    end
  end

  private

    def setup
      Thread.start {
        thread_proc
      }
    end

    def label_in_board_with_color board, color
      l = board.labels.find{|l| l.name == color}
      l ||= Trello::Label.create board_id:board.id, name:color, color:color
    end

    def thread_proc
      while arg = @worker_queue.pop
        begin
          event = arg[:event]

          board =  Trello::Board.all.find{|b| b.name == event[:board_name]}
          next unless board

          card_name = event[:card_name].dup || ""
          card_name.gsub!(/__value__/, arg[:value] || "") if arg[:value].is_a? String
          next if (card_name || "").empty?

          card = board.cards.find{|c| c.name == card_name}
          card ||= Trello::Card.create name:card_name

          # move card into a list
          list = board.lists.find{|l| l.name == event[:list_name]} if event[:list_name]
          card.move_to_list list if list

          # set color label
          if event[:color]
            if event[:color][:add]
              label = label_in_board_with_color board, event[:color][:add]
              card.add_label label
            end
            if event[:color][:remove]
              label = label_in_board_with_color board, event[:color][:remove]
              card.remove_label label
            end
          end

        rescue => e
          # TODO: Resend if it fails.
          p e
puts $!
puts $@
        end
      end
    end

end

end
end

def plugin_trello_init plc
  @trello_plugin = LadderDrive::Emulator::TrelloPlugin.new plc
end

def plugin_trello_exec plc
  @trello_plugin.run_cycle plc
end
