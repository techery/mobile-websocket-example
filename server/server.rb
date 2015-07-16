require "em-websocket"
require "rubythemis"
require "base64"

server_priv_key = "\x52\x45\x43\x32\x00\x00\x00\x2d\x49\x87\x04\x6b\x00\xf2\x06\x07\x7d\xc7\x1c\x59\xa1\x8f\x39\xfc\x94\x81\x3f\x9e\xc5\xba\x70\x6f\x93\x08\x8d\xe3\x85\x82\x5b\xf8\x3f\xc6\x9f\x0b\xdf"

$pub_keys = Hash.new
$sessions = Hash.new

class Callbacks_for_themis < Themis::Callbacks
    def get_pub_key_by_id(id)
        return $pub_keys[id].force_encoding("BINARY")
    end
end

EventMachine.run do
  @channel = EM::Channel.new


  EventMachine::WebSocket.start(host: "0.0.0.0", port: 8080, debug: true) do |ws|
    ws.onopen do
      stage = 0
      id = nil
      sid = @channel.subscribe { |msg| ws.send(msg) }
      

      ws.onmessage { |msg| 
	if stage == 0
	    id_pubkey = msg.split(":")
	    id=id_pubkey[0]
	    $pub_keys[id_pubkey[0]]=Base64.decode64(id_pubkey[1])
	    callbacks = Callbacks_for_themis.new
    	    ssession = Themis::Ssession.new("server", server_priv_key, callbacks)
    	    $sessions[id]=ssession
	    stage+=1
	else
	    res, mes = $sessions[id].unwrap(Base64.decode64(msg))
	    if res == 1 #Themis::SEND_AS_IS
		ws.send(Base64.encode64(mes))
	    else
		$sessions.each do |sid, session|
		    @channel.push(Base64.encode64($sessions[id].wrap(mes)))
		end
	    end
	end
    }

      ws.onclose { @channel.unsubscribe(sid) 
		   $sessions.delete(id)
		   $pub_keys.delete(id)
	}
    end
  end
end
