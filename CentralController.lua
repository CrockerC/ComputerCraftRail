--will not work if any single distance is greater than 1 million


function main()
	start()
	listenForRednet()
end

function start()
	rednet.open("back")
	nodes = readNodes() --nodes is intentionally global
	destinations = getDestinations()
	--print(dump(nodes))
end

function listenForRednet()
	while true do
		print("listening for rednet")
		local senderID, message, protocol = rednet.receive() 
		print("rednet message")
		
		--listen for a travel request
		if protocol == "travelRequest" then --message is {dest,source}
			print("getting travel request")
			local path = shortestPathDist(nodes,message[1],message[2])
			sendPath(path)
		end
		
		--listen for a nodeRequest
		if protocol == "nodeRequest" then --message is nodeID
			print("getting node request")
			sendNodes(senderID,message)
		end
		
		if protocol == "destRequest" then
			print("getting destination list request")
			sendDest(senderID)
		end
	end
end

function sendPath(path)
	rednet.broadcast(path,"path")
	print("sending path")
end

function sendNodes(senderID,nodeID)
	local ajacentNodes = {}
	
	for i,temp in ipairs(nodes[nodeID+1]) do
		if temp > 0 then
			table.insert(ajacentNodes,i-1)
		end
	end
	
	local message = ajacentNodes
	rednet.send(senderID,message,"nodeAnswer")	
	print("sending Node Answer")
end

function sendDest(senderID)
	local message = destinations
	rednet.send(senderID,message,"destAnswer")	
	print("sending destination Answer")
end

function getDestinations()
	local f = fs.open("destinations.txt", "r")
	local line = f.readLine()
	local destinations = {}
	i = 1
	while line ~= nil do
		destinations[i] = line
		line = f.readLine()
		i = i + 1
	end
	return destinations
end

function readNodes()
--this function reads a file containing all the 'nodes' of the network and every node that they are connected to
--if a new node is added, this file must be accurately updated for the new node to be able to be processed by the computer

	local nodes = {}
	local f = fs.open("nodes.txt", "r")
	local line = f.readLine()
	i = 1
	while (line ~= nil) do
		local node = mysplit(line,",") --node format is "1,2,3,4,5,etc" with the index of the node being the node's number and the values being the distance to the node of that index
		j = 1
		while node[j] do
			node[j] = tonumber(node[j])
			j = j + 1
		end
		nodes[i] = node
		line = f.readLine()
		i = i + 1
	end
	return nodes
	--so itll look something like this {{0,1,0,4},
	--									{1,0,2,0},
	--									{0,2,0,1},
	--									{4,0,1,0}}
end

function shortestPathDist(nodes,source,dest)
--finds the shortest path to the destination node from the source node
	local dist = {}
	local sptSet = {}
	local soln = {}
	local final = {}
	local path = {}
	for i=1,table.getn(nodes) do
		dist[i] = 1000000 --big number
		sptSet[i] = false
	end
	
	dist[source+1] = 0
	
	for i=1,table.getn(nodes) do
		u = minDist(table.getn(nodes),dist,sptSet)
		sptSet[u+1] = true
		
		for v=1,table.getn(nodes) do
			if (nodes[u+1][v] > 0) and (sptSet[v] == false) and (dist[v] > dist[u+1] + nodes[u+1][v]) then 
				dist[v] = dist[u+1] + nodes[u+1][v]
				table.insert(path,{u,v-1})
				if v-1 == dest then
					final = {u,v-1}
				end
			end
		end	
	end
	return shortestPathHelp(final,path,{final})
end

function shortestPathHelp(final,path,sPath)
--takes the list of shortest legs and extracts the shortest path to the destination
	local temp
	local leg
	
	for i=1,table.getn(path) do
		leg = path[i]
		if leg[2] == final[1] then
		
			--concatenate the temp and sPath tables
			temp = {leg}
			for p in sPath do
				table.insert(temp,p)
			end
			
			--recursion bois
			sPath = shortestPathHelp(leg,path,temp)
		end
	end
	return sPath
end

function minDist(vertices,dist,sptSet)
--just finds the minimum distance vertex from the list of vertices not in the shortest path tree
	local mini = 1000000 --big number
	local min_index = 0
	
		
	for i=1,vertices do
		if dist[i] < mini and sptSet[i] == false then
			mini = dist[i]
			min_index = i-1
		end
	end
	
	--print(min_index)
	return min_index
end

function mysplit(str, sep)
	str = str .. sep
	t = {}
	for w in str:gmatch("(.-),") do 
		table.insert(t,w)
	end
	return t
end

main()
