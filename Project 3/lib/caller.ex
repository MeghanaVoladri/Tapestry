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

  def sendRequests(listOfPids, numRequests) do
    Enum.map(listOfPids, fn x ->
      GenServer.cast(String.to_atom(x), {:sendRequest, numRequests, listOfPids, x})
    end)

    length(listOfPids) * numRequests
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
