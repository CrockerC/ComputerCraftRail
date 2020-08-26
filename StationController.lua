nodeID = 0 --the ID of this node, must not be the same as any other node and must be the same as the node controller

function main()
	start()
	
	while true do
		os.sleep(.1)
		dest = getInput()
		sendTravelRequest(dest)
	end
end

function start()
	peripheral.call("right", "clear")
	rednet.open("back")
	local dests = requestDestinations()
	dispDestinations(dests)
end

function sendTravelRequest(dest)
	rednet.broadcast({nodeID,dest},"travelRequest")
	print("sending travel Request")
end

function getInput()
	write("Destination: ")
	
	local dest = nil
	while dest == nil do
		dest = tonumber(read())
		if dest == nil then
			print("Must enter a number!")
		end
	end
	
	return dest
end

function dispDestinations(destinations)

	monitor = peripheral.wrap("right")
	
	if term.current then 
		monitor.restoreTo = term.current() 
	end
	
	term.redirect(monitor)
	--while true do
		for i,dest in ipairs(destinations) do
			print(i,":" ,dest)
			--os.sleep(.8)
		end
	--end
	if term.current then
		term.redirect(monitor.restoreTo)
	end
end

function requestDestinations()
	rednet.broadcast(nodeID,"destRequest")
	print("sending destination request")
	local senderID, message, protocol = rednet.receive("destAnswer") --message is {dest,source}	
	print("getting dest answer")
	return message
end

main()
