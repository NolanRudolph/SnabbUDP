module(..., package.seeall)

Sender = {}

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
local pci      = require("lib.hardware.pci")

local ffi =      require("ffi")
local C = ffi.C


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
			src = self._mac,
			dst = ethernet:pton("90:e2:ba:b3:ba:08"),
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
		print("Usage: SnabbUDP <data> <PCI> <IP> <port>")
		print("       data : File containing comma-separated numbers (e.g. 10,12.4,32)")
		print("       PCI  : PCI Address linked with the interface to send packets on")
		print("       IP   : IP Address of receiving user")
		print("       port : Port of the receiving user")
                main.exit(1)
        end
        
	local data_file = args[1]
	local pci_addr = args[2]
	local ip_dst = args[3]
	local port = args[4]

	-- Init config for engine
	local c = config.new()
	
	-- Resolving input/output given PCI address
	local device_info = pci.device_info(pci_addr)
	if device_info then
		config.app(c, "nic", require(device_info.driver).driver, 
		{
			pciaddr = pci_addr,
			mtu = 1500,
		})
		input, output = "nic."..device_info.rx, "nic."..device_info.tx
	else
		fatal(("Incompatible device from PCI %s"):format(pci_addr))
	end

	config.app(c, "sender", Sender, {data=data_file, ip_dst=ip_dst, port=tonumber(port)}) 

	config.link(c, "sender.output ->" .. output)
	
	engine.configure(c)
        engine.main({report = {showlinks=true}, duration = 1})
end
