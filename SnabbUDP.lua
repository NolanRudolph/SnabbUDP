module(..., package.seeall)

Sender = {}

local link =     require("core.link")
local app =      require("core.app")
local lib =      require("core.lib")
local config =   require("core.config")
local packet =   require("core.packet")
local ethernet = require("lib.protocol.ethernet")
local ipv4 =     require("lib.protocol.ipv4")
local udp =      require("lib.protocol.udp")
local datagram = require("lib.protocol.datagram")
local raw_sock = require("apps.socket.raw")

local ffi =      require("ffi")
local C = ffi.C


function Sender:new(args)
	print("Hi! You made it to Sender:new()!")

	-- Set variables using args
	data_file = io.open(args["data"], "r")
	ip_dst = args["ip_dst"]
	port = args["port"]

	-- Get total length of file
	local start = data_file:seek()
	local file_size = data_file:seek("end")
	data_file:seek("set", start)

	-- Set input file as data for io.read("*all")
	io.input(data_file)

	local o = 
	{
		ether = ethernet:new(
		{
			src = self._mac,
			dst = ethernet:pton("90:e2:ba:b3:ba:08"),
			type = 0x0800
		}),
		ip = ipv4:new(
		{
	                ihl_v_tos = 0x4500,
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
		dgram = datagram:new(),
		payload_length = file_size,
		payload = io.read("*all")
	}
	return setmetatable(o, {__index = Sender})
end

function Sender:gen_packet()
	local p = packet.allocate()
	
	self.dgram:new(p)
	self.dgram:push(self.udp)
	self.dgram:push(self.ip)
	self.dgram:push(self.ether)
	self.dgram:payload(self.payload, self.payload_length)
	
	return self.dgram:packet()
end


function Sender:pull()
	assert(self.output.output, "No compatible output port found.")
	-- print("Sending packet!")
	link.transmit(self.output.output, self:gen_packet())
end

function test_ports(app, name)
	assert(app.input, "No input port found for " .. name .. ".")
	assert(app.output, "No output port found for " .. name .. ".")
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
	config.app(c, "sender", Sender, {data=data_file, ip_dst=ip_dst, port=tonumber(port)}) 
	config.link(c, "sender.output->server.rx")
	--config.link(c, "server.rx->server.tx")
	--print("Link server.input has " .. link.nreadable(RawSocket) .. " packets.")
	engine.configure(c)
        engine.main({report = {showlinks=true}, duration = 1})
end
