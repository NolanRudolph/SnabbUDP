module(..., package.seeall)

Sender = {}

local ffi =      require("ffi")
local link =     require("core.link")
local app =      require("core.app")
local lib =      require("core.lib")
local packet =   require("core.packet")
local ethernet = require("lib.protocol.ethernet")
local ipv4 =     require("lib.protocol.ipv4")
local udp =      require("lib.protocol.udp")
local datagram = require("lib.protocol.datagram")
local raw_sock = require("apps.socket.raw")
local transmit, receive = link.transmit, link.receive


function Sender:new(data, ip_dst, port)
	print("Hi! You made it to Sender:new()!")
	local o = 
	{
		ether = ethernet:new(
		{
			ether_dhost = "90:e2:ba:b3:ba:08",
			ether_type = 8
		}),
		ip = ipv4:new(
		{
	                ihl_v_tos = bit.lshift(4, 12) + bit.lshift(20, 8),
        	        -- IMPLEMENT total_length = ???
                	ttl = 255,
	                protocol = 17,
        	        -- IMPLEMENT checksum = ???
                	dst_ip = ip_dst
		}),
		udp = udp:new(
		{
			dst_port = port,
                	-- IMPLEMENT len = ???
                	-- IMPLEMENT checksum = ???
		}),
		dgram = datagram:new()
	}
	return setmetatable(o, {__index = Sender})
end

function Sender:gen_packet()
	local p = packet.allocate()
	-- Size of Ethernet Header = 14
        -- Size of IP Header = 20
        -- Size of UDP Header = 8
        -- Size of entire packet = 14 + 20 + 8 + Payload = 42 + Payload
	p.length = 42	

	self.dgram:new(p)
	self.dgram:push(self.udp)
	self.dgram:push(self.ip)
	self.dgram:push(self.ether)
	return self.dgram:packet()
end

function Sender:pull()
	print("Sending packet!")
	return self:gen_packet()
end



function run (args)
        if not (#args == 4) then
                -- print("Usage: send_data <data> <PCI addr> <interface> <ether> <IP> <port>")
		print("Usage: SnabbUDP <data> <IF> <IP> <port>")
		print("       data: File containing comma-separated numbers (e.g. 10,12.4,32)")
		print("       IF: Interface for packet(s) to be sent on")
		print("       port: Port of the receiving user")
		print("       IP: IP Address of receiving user")
                main.exit(1)
        end
        
	local data_file = args[1]
        local IF = args[2]
	local ip_dst = args[3]
	local port = args[4]
	
	local c = config.new()
	local RawSocket = raw_sock.RawSocket
	config.app(c, "server", RawSocket, IF)
        
	sender = Sender:new()
	config.app(c, "sender", sender, 
		   {data=data_file, ip_dst=ip_dst, port=port})
	config.link(c, "sender.output->server.input")
	
	engine.configure(c)
        engine.main({report = {showlinks=true}, duration = 1})
end
