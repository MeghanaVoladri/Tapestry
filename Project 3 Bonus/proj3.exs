defmodule Project3 do

    [first, middle, last] = System.argv
    {nodes, _} = Integer.parse(first)
    {numRequests, _} = Integer.parse(middle)
    {numFail, _} = Integer.parse(last)
    Process.register(self(),:main)
    numNodes = ceil(nodes*0.9)
    listOfNodePids = Caller.createNodes(numNodes)
    IO.puts "Network created"    

    listOfNewNodes = Caller.joinNodes(numNodes+1, nodes, listOfNodePids)
    IO.puts "New nodes joined"    

    
    requestCount = Caller.sendRequests(listOfNewNodes,numRequests, numFail)
    IO.puts "Number of requests sent: #{requestCount}"
  
    maxHop = Caller.getHopCount(0,0, requestCount )
    IO.puts "Maximum Hops are: #{maxHop}"
   end
  
  