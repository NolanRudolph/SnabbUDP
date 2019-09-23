module(..., package.seeall)

local link     = require("core.link")
local app      = require("core.app")
local lib      = require("core.lib")
local config   = require("core.config")
local packet   = require("core.packet")
local ethernet = require("lib.protocol.ethernet")
local ipv4     = require("lib.protocol.ipv4")
local udp      = require("lib.protocol.udp")
local datagram = require("lib.protocol.datagram")
local raw_sock = require("apps.socket.raw")

local ffi =      require("ffi")
local C = ffi.C

is_done = false
Sender = {}

function Sender:new(args)
	print("Hi! You made it to Sender:new()!")

	-- Set variables using args
	data_file = io.open(args["data"], "r")
	ip_dst = args["ip_dst"]
	port = args["port"]

	print("ip_dst = " .. ip_dst)
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
			src = ethernet:pton("90:e2:ba:b3:75:bd"),
			dst = ethernet:pton("90:e2:ba:b3:ba:09"),
			type = 0x0800
		}),
		ip = ipv4:new(
		{
	              	ihl = 0x4500,
        	        -- IMPLEMENT total_length = ???
                	ttl = 255,
	                protocol = 17,
        	        -- IMPLEMENT checksum = ???
                	dst = ipv4:pton(ip_dst)
		}),
		udp = udp:new(
		{
			dst_port = port,
                	-- IMPLEMENT len = ???
                	-- IMPLEMENT checksum = ???
		}),
		dgram = datagram:new(),
		payload_size = file_size,
		payload = io.read("*all")
	}
	return setmetatable(o, {__index = Sender})
end

function Sender:gen_packet()
	local SAFE_SIZE = 1300
	-- Spread the data amongst multiple packets if > MTU
	-- 1342 (1300 + layers) is a safe bet for not being dropped
	if self.payload_size > SAFE_SIZE then
		local num_packets = math.ceil(self.payload_size / SAFE_SIZE)
		local packet_list = {}
		local cur_char = 0
		for i = 1, num_packets do
			local p = packet.allocate()
			self.dgram:new(p)
			self.dgram:push(self.udp)
			self.dgram:push(self.ip)
			self.dgram:push(self.ether)
			if cur_char + SAFE_SIZE > self.payload_size then
				payload = string.sub(self.payload, cur_char, self.payload_size)
				self.dgram:payload(payload, self.payload_size - cur_char)
			else
				payload = string.sub(self.payload, cur_char, cur_char + SAFE_SIZE)
				self.dgram:payload(payload, SAFE_SIZE)
			end
			
			cur_char = cur_char + SAFE_SIZE
			table.insert(packet_list, self.dgram:packet())
		end
		return packet_list
	else
		local p = packet.allocate()
	
		self.dgram:new(p)
		self.dgram:push(self.udp)
		self.dgram:push(self.ip)
		self.dgram:push(self.ether)
		self.dgram:payload(self.payload, self.payload_size)
	
		return self.dgram:packet()
	end
end


function Sender:pull()
	assert(self.output.output, "No compatible output port found.")
	gen_pack_ret = self:gen_packet()
	if type(gen_pack_ret) == "table" then
		for i = 1, #gen_pack_ret do
			link.transmit(self.output.output, gen_pack_ret[i])
		end
	else
		link.transmit(self.output.output, gen_pack_ret)
	end
	is_done = true
end

function is_done()
	if is_done then
		return true
	else
		return false
	end
end


function run (args)
        if not (#args == 4) then
		print("Usage: SnabbUDP <data> <IF> <IP> <port>")
		print("       data : File containing comma-separated numbers (e.g. 10,12.4,32)")
		print("       IF   : Interface for packet(s) to be sent on")
		print("       port : Port of the receiving user")
		print("       IP   : IP Address of receiving user")
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

	engine.configure(c)
        engine.main({report = {showlinks=true}, done = is_done})
end
