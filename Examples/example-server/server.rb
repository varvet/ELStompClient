require "stompede"

class BridgeStomplet < Stompede::Stomplet
  def on_send(frame)
    session.message_all(frame.destination, frame.body)
  end
end

Stompede::WebSocketServer.new(BridgeStomplet).listen("0.0.0.0", 8675)

puts "Listening... press enter to kill"
gets
