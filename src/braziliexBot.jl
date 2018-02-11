
	
	include("braziliexBotFunctions.jl")	
	using Braziliex
	Braziliex.braziliexsetauth("YOUR KEY GOES HERE", "YOUR SECRET GOES HERE")	
	




	markets = Braziliex.ticker()
	currencies = Braziliex.currencies()
	amountofcurrencies = length(currencies)

	currencies_vertexes = Dict()
	vertex_id = 1 #This is actually never used...but perhaps I may use it in the future...well, leave this variable alone
	for x in keys(currencies)
	       currencies_vertexes[x] = ExVertex(vertex_id, x)
	       vertex_id = vertex_id+1
	end



	edge_id = 1
	currencies_edges = Dict()
	for x in keys(markets)

		
		asks = Braziliex.orderbook(x)["asks"]
		bids = Braziliex.orderbook(x)["bids"]

		bestask = asks[1]
		bestbid = bids[1]

		pair = split(x,"_") #bch_btc becomes "bch" "btc"
		currA = String(pair[1])
		currB = String(pair[2])

		newedge = createedge(edge_id,currA,currB)
		newedge.attributes["price"] = calcprice(currA,currB,"highestBid")
		newedge.attributes["amount"] = bestbid["amount"]

		currencies_edges[string(currA,"_",currB)] = newedge				
		edge_id = edge_id+1

		newedge = createedge(edge_id,currB,currA)
		newedge.attributes["price"] = calcprice(currA,currB,"lowestAsk")
		newedge.attributes["amount"] = bestask["amount"]
		currencies_edges[string(currB,"_",currA)] = newedge	
		
		edge_id = edge_id+1
	end

	global edge = edgelist(collect(values(currencies_vertexes)),collect(values(currencies_edges)))

	for (x=1:length(edge.edges))
		

		currentedge = edge.edges[x]
		edge.vertices[currentedge.source.index].attributes[currentedge.target.label] = currentedge
		
	end

	adj = adjlist(collect(keys(currencies_vertexes)))
	for x in keys(markets)

		pair = split(x,"_") #bch_btc becomes "bch" "btc"
		currA = String(pair[1])
		currB = String(pair[2])

		add_edge!(adj,currA,currB)
		add_edge!(adj,currB,currA)
	end

	my_btc = Braziliex.balance("btc")
	my_brl = Braziliex.balance("brl")

	tentativas = 0
	#while(true)
		
		
		loopcycles(my_brl,"brl",my_btc,"btc")
		print_with_color(:green,"TENTATIVA: ")		
		print(tentativas,"\n")
		sleep(10)

		tentativas = tentativas + 1		
	#end
	#loopcycles(initialamount,startingCurr,initialamount2,startingCurr2)


#f() = findneighboredge("brl","sngls").attributes
#g() = findneighboredge("sngls","brl").attributes

#t = f()
#n = g()

	#showprices("brl","btg",true)
