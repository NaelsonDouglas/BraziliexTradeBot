	import HTTP
	import JSON
	import Nettle
	#import IJuliaPortrayals
	using Graphs

	#could not spawn `neato -Tx11` --->
	#https://github.com/JuliaArchive/Graphs.jl/issues/215

	#0.5% of fee --> https://braziliex.com/exchange/fees.php

	 
	

	

function createedge(id::Int,source::String,destiny::String)
	ExEdge(edge_id,currencies_vertexes[source],currencies_vertexes[destiny])
end

function calcprice(sourceCurr::String, marketCurr::String, askorbid::String)
	price = parse(markets[string(sourceCurr,"_",marketCurr)][askorbid])	

	if (askorbid == "lowestAsk" )
		
		price = 1/price
	end 	
	return price
end


function showprices()

	for x=1:length(edge.edges)
		source = edge.edges[x].source.label
		target = edge.edges[x].target.label		
		price = edge.edges[x].attributes["price"]
		print(source," ---> ",target," = ",@sprintf("%.8f",price)," ",uppercase(target),"\n")
	end
end

function showprices(currA::String="",currB::String="",exclusive::Bool=false)

	if (currA == "") #it allows the use of showprice() without arguments given
		currA = "btc"
		currB = "brl"

	end

	for x=1:length(edge.edges)
		source = string(edge.edges[x].source.label)
		target = string(edge.edges[x].target.label)	

		if (exclusive)	
			if ((source == currA && target == currB) || (source == currB && target == currA))
				price = edge.edges[x].attributes["price"]			

				print(source," ---> ",target," = ",@sprintf("%.8f",price)," ",uppercase(target),"\n")
			end

		elseif (source == currA || target == currB)
			price = edge.edges[x].attributes["price"]			

			print(source," ---> ",target," = ",@sprintf("%.8f",price)," ",uppercase(target),"\n")
		end 
	end
end

function getvertexlabel(vertex::Graphs.ExVertex)
		vertex.label
end


function checkneighbors()
	print("\n")
	for x=1:length(edge.vertices)
		print(edge.vertices[x].label,"--> ")
		for i in keys(edge.vertices[x].attributes)
			print(edge.vertices[x].attributes[i].label," ")			
		end		
		print("\n")
	end
end



function findvertexbyename(currency::String)
	vertexID = find(x -> x.label == currency,edge.vertices)
	return edge.vertices[vertexID][1] #for some reason it was returning an array with one element. SO I put this [1] to return only the element
end


function findneighboredge(source::String, neighborname::String)
	
	sourceneighbors = findvertexbyename(source).attributes

	if(in(neighborname,keys(sourceneighbors)))
		return sourceneighbors[neighborname]
	else
		return "null"
	end
end

#"calculate the maximum outcome you can get from the link"
function linkmaxincome(link::Graphs.ExEdge)
	link.attributes["price"] * link.attributes["amount"]
end

function getmarketfromedge(edge::Graphs.ExEdge)
	source = edge.source.label
	target = edge.target.label
	separator = "_"

	if (source == "brl")
		return string(target,separator,source)
	elseif (target == "brl")
		return string(source,separator,target)
	elseif (target == "btc")
		return string(source,separator,target)
	elseif (source == "btc")
		return string(target,separator,source)
	else
		print("You trying to buy on a unnexisting market")
		return("unnexisting_market")
	end
end

function wronglinkwarning(myposition::String,market::String,link::Graphs.ExEdge)
	println("Erro. O link provavelmente está errado")
	println(link)
	println("Minha posição, ", myposition)
	println("Mercado, ", market)
end	

function maxusedmoney(availablemoney::Float64, link::Graphs.ExEdge)
	if(link.source.label == "btc" && link.target.label == "brl")
		linkmax = link.attributes["amount"] * link.attributes["price"]
	else
		linkmax = link.attributes["amount"] / link.attributes["price"]
	end


	if availablemoney > linkmax
		return linkmax
	else
		return availablemoney
	end
	
end

function calculatefee(money::Float64)
	fee = 0.9975	
	return money*fee
end

function performtrade(amount::Float64,myposition::String,link::Graphs.ExEdge)
	market = getmarketfromedge(link)
	currencies = split(market,"_")

	#we will need it later
	amnt_inhands = amount



	

	visitorcurr = currencies[1]
	marketcurr = currencies[2]

	tradefunction = "null"
	functionname = ""

	#check if my position is A and I'm trying to use a link B->A instead of A->B
	if (myposition != link.source.label)
		wronglinkwarning(myposition,market,link)
		return "error"			
	else

	buyingprice = 0.0
	if (myposition == marketcurr)
		tradefunction = Braziliex.buy
		buyingprice = 1/link.attributes["price"]		
		functionname = "buy"	
		amnt_inhands = amnt_inhands/buyingprice	
		elseif (myposition == visitorcurr)
			tradefunction = Braziliex.sell
			buyingprice = link.attributes["price"]
			functionname = "sell"
		else
			print("ERROR 176")
			return "error"
		end	
	end

	if (myposition == "brl")
		amnt_inhands = round(amnt_inhands,2)
	elseif (myposition == "btc")
		amnt_inhands = round(amnt_inhands,8)
	end
	
	println("[",functionname,"] amount=[",string(amnt_inhands),link.target.label, "] price=[",buyingprice,link.target.label,"]"," market=[",market,"]\n")
	tradefunction(amnt_inhands, buyingprice,getmarketfromedge(link))
end

function findcycle(secondCurr::String, availablemoney::Float64,startingMkt="brl" )	
	oppositeMkt = ""	
	if (startingMkt == "btc")
		oppositeMkt = "brl"
	else
		oppositeMkt = "btc"
	end


	
	link1 = findneighboredge(startingMkt, secondCurr)
	link2 = findneighboredge(secondCurr, oppositeMkt)
	link3 = findneighboredge(oppositeMkt, startingMkt)


	println("===================================================")
	if (link1 != "null" && link2 != "null" && link3 != "null")
		#println(link1)
		#println(link1.attributes)
		initialmoney = maxusedmoney(availablemoney,link1)

		

		step1 = initialmoney * link1.attributes["price"];
		step1 = calculatefee(step1)
		

		step2 = step1 * link2.attributes["price"]
		step2 = calculatefee(step2)


		step3 = step2 * link3.attributes["price"]
		step3 = calculatefee(step3)

		

		
		#printsteps(link1,link2,link3,initialmoney,step1,step2,step3)
		println()
		
		#This line is to force the if to be activated.
		#step3 = 2*step3 # TODO REMOVE THIS LINE WHEN IN PRODUCTION. IT'S HERE FOR TESTS PURPOSES

		minproffitrate = 0.95 #It means 1.5%
		minproffit_brl = 2 #the minimum brl acceptable profit is R$2
		minproffit_btc = 0.00006

		totalprofitable = minproffitrate*initialmoney
		println("===================================================")
		println("Initialmoney: ",initialmoney," totalprofitable ", totalprofitable)
		println("===================================================")
		if (step3 > totalprofitable)
			sleeptime=6
			println("Found a trade. Will follow it if it's worth.")
			if ( true #= (startingMkt == "brl" && (step3 - initialmoney >= minproffit_brl)) ||
				 (startingMkt == "btc" && (step3 - initialmoney >= minproffit_btc)) =#
				)

				performtrade(initialmoney, link1.source.label, link1)		
				sleep(sleeptime/2)
				step1_pocketed =  Braziliex.balance(link1.target.label)
			
				print("\nStarted trading\n")				
				print("Waiting ",sleeptime," seconds to let the exchange to process the order\n\n")
				sleep(sleeptime)
				Braziliex.cancellorders(getmarketfromedge(link1))
				sleep(sleeptime/2)






				performtrade(step1_pocketed, link2.source.label, link2) #TODO fazer isso retornar o pocketed
				sleep(sleeptime/2)
				step2_pocketed =  Braziliex.balance(link2.source.label)
				Braziliex.cancellorders(getmarketfromedge(link2))
				sleep(sleeptime/2)

				performtrade(step2_pocketed, link3.source.label, link3)
				step3_pocketed =  Braziliex.balance(link3.target.label)

				proffitpercent = step3_pocketed/initialmoney						
				printgoodtrade(proffitpercent)

				#exit()
			end
		end
		println()
	else
		#do nothing...for the moment
	end
end


function printgoodtrade(proffitpercent::Float64)
		print_with_color(:green,"=====================\n")
			println("FOUND A GOOD TRADE!")
			println("Proffit of:",round(100*proffitpercent,2),"%")
			print_with_color(:green,"=====================\n")	
end

function printsteps(link1,link2,link3,initialmoney::Float64,step1::Float64,step2::Float64,step3::Float64)
	println(link1.source.label,"->",link2.source.label,"->",link3.source.label,"->",link3.target.label)
		println("[",initialmoney,"]",
				link1.source.label,"-->[",step1,"]",
				link2.source.label,"-->[",step2,"]",
				link3.source.label,"-->[",step3,"]",
				link1.source.label
			)
end


function loopcycles(startamount::Float64, startingCurr1::String,startamount2::Float64, startingCurr2::String="")

	currencies = map(getvertexlabel,collect(edge.vertices))
	
		for x in currencies
				findcycle(x, startamount,startingCurr1)
			if (startingCurr2 != "")
				findcycle(x, startamount2,startingCurr2)			
			end
		end

end




