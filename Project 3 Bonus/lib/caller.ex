defmodule Caller do
  def createNodes(numNodes) do
    listOfPids =
      Enum.reduce(1..numNodes, [], fn i, acc ->
        nodeId = createGUID(i)
        pid = Tapestry.start_link()
        Process.register(elem(pid, 1), String.to_atom(nodeId))
        acc ++ [nodeId]
      end)

    sortedListOfPids = Enum.sort(listOfPids)

    Enum.map(sortedListOfPids, fn x -> Tapestry.nodeInit(x, sortedListOfPids) end)
    listOfPids
  end

  def joinNodes(num1, num2, listOfNodePids) do
    listOfPids =
      Enum.reduce(num1..num2, [], fn i, acc ->
        nodeId = createGUID(i)
        pid = Tapestry.start_link()
        Process.register(elem(pid, 1), String.to_atom(nodeId))
        acc ++ [nodeId]
      end)

    sortedListOfPids = Enum.sort(listOfPids)

    Enum.map(sortedListOfPids, fn x ->
      Tapestry.newNodeInit(x, sortedListOfPids, listOfNodePids)
    end)

    listOfNodePids ++ listOfPids
  end

  def createGUID(i) do
    hash = String.slice(:crypto.hash(:sha256, to_string(i)) |> Base.encode16(), 56..63)
    hash
  end

  def sendRequests(listOfPids, numRequests, numFail) do
    listOfPidsAfterKill = killNodes(listOfPids, numRequests, numFail, 0)

    Enum.map(listOfPidsAfterKill, fn x ->
      GenServer.cast(String.to_atom(x), {:sendRequest, numRequests, listOfPidsAfterKill, x})
    end)

    (length(listOfPids) - numFail) * numRequests
  end

  def killNodes(listOfPids, numRequests, numFail, nodesFailed) do
    if nodesFailed < numFail do
      getRandomNode = :rand.uniform(length(listOfPids)) - 1
      failedNode = Enum.at(listOfPids, getRandomNode)
      failedNodeId = Process.whereis(String.to_atom(failedNode))

      if failedNodeId != nil do
        Process.exit(failedNodeId, :kill)
        listOfPids = listOfPids -- [failedNodeId]
        killNodes(listOfPids, numRequests, numFail, nodesFailed + 1)
      else
        killNodes(listOfPids, numRequests, numFail, nodesFailed)
      end
    end
    listOfPids
  end

  def getHopCount(max, i, count) do
    receive do
      {:delivered, hop_count} ->
        max = getMaxNumber(max, hop_count)

        if i + 1 < count do
          max = getHopCount(max, i + 1, count)
        else
          max
        end
    end
  end

  def getMaxNumber(num1, num2) do
    if num1 > num2 do
      num1
    else
      num2
    end
  end
end
