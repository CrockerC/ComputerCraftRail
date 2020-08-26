nodeID = 0 --the ID of this node, must not be the same as any other node
queueIn = {}
queueOut = {}
travel = {}
connectedNodes = {} --each node can only have up to 8 connected nodes

function main()
	start()
	
	while true do
		waitForInput()
	end
end

function start()
	rednet.open("bottom")
	requestNodes()
end

function waitForInput()
	local event,p1,p2,p3
	
	while true do
		print("listening for input")
		event,p1,p2,p3 = os.pullEvent()
		
		if event == "redstone" then
			decideRedstone(p1)
			return
		end
		
		if event == "rednet_message" then
			decideRednet(p1,p2,p3)
		end
	end
end

function getCarts()
	return carts
end

function decideRedstone(side)
	if redstone.getInput("bottom") then
		redstone.setOutput("front",true)
		table.remove(queueIn)
	end
			
	if redstone.getInput("top") then
		redstone.setOutput("front",false)
	end
end

function requestNodes()
	rednet.broadcast(nodeID,"nodeRequest")
	print("sending node request")
	local senderID, message, protocol = rednet.receive("nodeAnswer") --message is {dest,source}	
	print("getting node answer")
	connectedNodes = message
end

function decideRednet(senderID,message,protocol)
	if protocol == "path" then  --message is {source,dest} for all legs of path
		print("getting path")
		local leg
		--when a traveler has made a request to enter the network
		for i=1,table.getn(message) do
			leg = message[i]
			if leg[1] == nodeID then
				--this will only be used when a traveler is leaving a station
				table.insert(queueOut,leg[1])
				traveler(leg[2])
				table.remove(queueOut)
			end
			
			if leg[2] == nodeID then
				table.insert(queueIn,leg[2])
			end
		end
	end
		
	if protocol == "traveler" then --message is {dest,source}
		print("getting new traveler")
		--when a traveler is currently on their way to the station/node from the neighboring node
		if message[2] == nodeID then
			--this queues up multiple travelers
			waitForInput()

		end
	end
end

function traveler(dest)
	rednet.broadcast({nodeID,dest},"traveler")
	print("sending traveler")
	for i,node in ipairs(connectedNodes) do
		if node == dest then
			sendToNode(i)
			while os.pullEvent("redstone") do
				if redstone.getInput("top") then
					redstone.setOutput("left",false)
					redstone.setOutput("right",false)
					return
				end
			end
		end
	end
end

function sendToNode(thNode)
--simply outputs the nth node in binary (00 - 11)
	redstone.setOutput("left",false)
	redstone.setOutput("right",false)

	local left = 0
	if thNode > 3 then
		left = math.floor(thNode / 4)
	end
	
	thNode = thNode - left * 4
	local back = 0
	if thNode > 1 then
		back = math.floor(thNode / 2)
	end
	
	thNode = thNode - back * 2
	local right = thNode
	
	redstone.setOutput("left",left > 0)
	redstone.setOutput("right",right > 0)
	redstone.setOutput("front", true)
end

main()
