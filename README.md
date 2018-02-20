# BraziliexTradeBot

This code relies on the [JuliaBraziliexAPI](https://github.com/NaelsonDouglas/BraziliexJuliaAPI)
The code itself works, but it needs some twerking for that. (like setting the API keys manualy) 
It's currently a cut-off part of a bigger bot (which is being kept in private).


It works by creating a graph of all trading pairs and keeps finding possible cycles where you can keep selling/buying at market's price and returning to the starting currency with some revenue

![image](https://i.imgur.com/EnTaXxI.jpg)

Disclaimer: This image was taken from the initial bot version, which was intended to work in Bitgrail exchange, but it sadly got hacked and is out of use. Braziliex doesnt have a XRB pair.
