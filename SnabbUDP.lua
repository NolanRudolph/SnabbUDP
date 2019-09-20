module(..., package.seeall)

sendData = {}

local ffi =      require("ffi")
local link =     require("core.link")
local lib =      require("core.lib")
local packet =   require("core.packet")
local ethernet = require("lib.protocol.ethernet")
local ipv4 =     require("lib.protocol.ipv4")
local udp =      require("lib.protocol.udp")
local raw_sock = require("apps.socket.raw")
local transmit, receive = link.transmit, link.receive


function sendData:new()
	return setmetatable({}, {__index = sendData})
end

function sendData:createPacket(data, ip_dst, port)
	local ether_hdr = ethernet:init(
	{
		ether_type = 8
	})
	local ip_hdr = ipv4:init(
	{
		ihl_v_tos = bit.lshift(4, 12) + bit.lshift(20, 8),
		-- IMPLEMENT total_length = ???
		ttl = 255,
		protocol = 17,
		-- IMPLEMENT checksum = ???
		dst_ip = ip_dst
	})
	local udp_hdr = udp:new(
	{
		dst_port = port
		-- IMPLEMENT len = ???
		-- IMPLEMENT checksum = ???
	})

	-- Size of Ethernet Header = 14
	-- Size of IP Header = 20
	-- Size of UDP Header = 8
	-- Size of entire packet = 14 + 20 + 8 + Payload = 42 + Payload
	ret_packet = packet.allocate()
	ret_packet.length = 42
	link.transmit("server", ret_packet)
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
        local pci = args[2]
        local IF = args[3]
	local ether_dst = args[4]
	local port = args[5]
	local ip_dst = args[6]

        local c = config.new()
	-- config.app(c, "nic", IntelX520, {pciaddr = pci})
	local RawSocket = raw_sock.RawSocket
	config.app(c, "server", RawSocket, IF)
	config.link(c, "server.tx -> server.rx")

        engine.configure(c)
        engine.main({report = {showlinks=true}})

end
