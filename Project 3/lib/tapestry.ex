defmodule Tapestry do
    use GenServer
  
    def start_link() do
      GenServer.start(__MODULE__, [])
    end
  
    def init([]) do
      root = []
      dht = MapSet.new()
      {:ok, [root, dht]}
    end
  
    def nodeInit(pid, sortedListOfPids) do
      routingTable = calculateRoutingTable(pid, sortedListOfPids, "")
      newRoutingTable(pid, routingTable)
    end
  
    def newNodeInit(pid, sortedListOfPids, listOfNodePids) do
      neighbourList = getNearestNodes(0, pid, listOfNodePids)
      sendMulticast(pid, neighbourList)
      fullList = Enum.sort(sortedListOfPids ++ listOfNodePids)
      routingTable = calculateRoutingTable(pid, fullList, Enum.at(neighbourList, 0))
      newRoutingTable(pid, routingTable)
    end
  
    def getNearestNodes(index, pid, listOfPids) do
      len = length(listOfPids)
      prefix = String.slice(pid, index, 1)
  
      result =
        Enum.reduce(0..len, [], fn i, _acc ->
          Enum.filter(listOfPids, fn y -> String.slice(y, index, 1) == prefix end)
        end)
  
      len = length(result)
      neighbours = []
  
      neighbours =
        if(len == 1) do
          result
        else
          if(len == 0) do
            if(index == 0) do
              []
            else
              listOfPids
            end
          else
            getNearestNodes(index + 1, pid, result)
          end
        end
  
      neighbours
    end
  
    def calculateRoutingTable(pid, sortedListOfPids, indicator) do
      finalRT =
        if(indicator != "") do
          hexCodes = [
            "0",
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "9",
            "A",
            "B",
            "C",
            "D",
            "E",
            "F"
          ]
  
          id = Process.whereis(String.to_atom(indicator))
          [_, neighbourRT] = :sys.get_state(id)
  
          routingTable = neighbourRT
          newTable = []
          row = largestPrefixLength(indicator, pid)
          col = Enum.find_index(hexCodes, fn x -> String.at(indicator, row) == x end)
  
          if !Enum.at(Enum.at(routingTable, row), col) do
            newRow = List.replace_at(Enum.at(routingTable, row), col, indicator)
            newTable = List.replace_at(routingTable, row, newRow)
          end
        else
          idList = sortedListOfPids -- [pid]
  
          routingTable =
            Enum.reduce(0..7, [], fn i, acc ->
              prefix = String.slice(pid, 0, i)
              row = calculateRow(idList, prefix)
              acc ++ [row]
            end)
  
          routingTable
        end
  
      finalRT
    end
  
    def calculateRow(id_list, prefix) do
      hexCodes = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
  
      row =
        Enum.map(hexCodes, fn x ->
          Enum.find(id_list, fn y -> String.starts_with?(y, prefix <> x) end)
        end)
  
      row
    end
  
    def newRoutingTable(pid, routingTable) do
      GenServer.cast(String.to_atom(pid), {:newRoutingTable, routingTable})
    end
  
    def sendMulticast(pid, neighbourList) do
      GenServer.cast(String.to_atom(pid), {:sendMulticast, neighbourList})
    end
  
    
    def updateRoutingTable(neighbourList, _state) do
      selfNodeId = Atom.to_string(Process.info(self()) |> Enum.at(0) |> elem(1))
      hexCodes = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
      len = length(neighbourList)
      newTable = []
  
      for i <- 0..len do
        pid = Enum.at(neighbourList, len - 1)
        id = Process.whereis(String.to_atom(pid))
        [_, routingTable] = :sys.get_state(id)
  
        row = largestPrefixLength(pid, selfNodeId)
        col = Enum.find_index(hexCodes, fn x -> String.at(pid, row) == x end)
  
        if !Enum.at(Enum.at(routingTable, row), col) do
          newRow = List.replace_at(Enum.at(routingTable, row), col, pid)
          newTable = List.replace_at(routingTable, row, newRow)
        end
  
        newRoutingTable(selfNodeId, newTable)
      end
    end
  
    def largestPrefixLength(key, selfNodeId) do
      keywordsList = String.myers_difference(key, selfNodeId)
      tuple = hd(keywordsList)
  
      if elem(tuple, 0) != :eq do
        0
      else
        prefix = Keyword.get(keywordsList, :eq)
        len = String.length(prefix)
        len
      end
    end
  
    def sendMessages(numRequests, listOfPids, x, state) do
      len = length(listOfPids)
  
      for i <- 1..numRequests do
        Process.sleep(1000)
        key = selectNode(listOfPids, len)
        message = x <> " sends " <> key <> " "
        route(message, key, x, 0, state, listOfPids)
      end
    end
  
    def selectNode(listOfPids, len) do
      Enum.at(listOfPids, :rand.uniform(len) - 1)
    end
  
    def route(message, key, x, hopCount, state, listOfPids) do
      if key == x do
        deliver(hopCount)
      else
        nextNode = findNextNode(key, x, state, listOfPids)
  
        if nextNode == x do
          deliver(hopCount + 1)
        else
          forward(message, key, nextNode, hopCount + 1, listOfPids)
        end
      end
    end
  
    def deliver(hopCount) do
      send(:main, {:delivered, hopCount})
    end
  
    def findNextNode(key, x, state, listOfPids) do
      neighbourList = Enum.at(state, 0)
      neighbourList = Enum.sort(neighbourList)
      hexCodes = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
      routingTable = Enum.at(state, 1)
  
      if(routingTable != nil) do
        row = largestPrefixLength(key, x)
        col = Enum.find_index(hexCodes, fn x -> String.at(key, row) == x end)
        routingRow = Enum.at(routingTable, row)
  
        if routingRow != nil do
          newList = Enum.filter(routingRow, &(!is_nil(&1)))
          finalList = neighbourList ++ newList
  
          result = searchNeighbourList(finalList, key)
  
          if (result != nil) && (keyDifference(key, result) > keyDifference(key, x))do
            result
          else
            x
          end
        else
            Enum.at(listOfPids, :rand.uniform(length(listOfPids)) - 1)
        end
      else
        Enum.at(listOfPids, :rand.uniform(length(listOfPids)) - 1)
      end
    end
  
    def keyDifference(key1, key2) do
      abs(elem(Integer.parse(key1, 16), 0) - elem(Integer.parse(key2, 16), 0))
    end
  
    def searchNeighbourList(totalSet, key) do
      newSet = totalSet
      keyInt = elem(Integer.parse(key, 16), 0)
      neighbourSetInt = Enum.map(newSet, fn x -> abs(elem(Integer.parse(x, 16), 0) - keyInt) end)
  
      if(length(neighbourSetInt) != 0) do
        closest = Enum.min(neighbourSetInt)
        index = Enum.find_index(neighbourSetInt, fn x -> x == closest end)
        Enum.at(totalSet, index)
      else
        Enum.at(totalSet, key)
      end
    end
  
    def forward(message, key, nextNode, hopCount, listOfPids) do
      GenServer.cast(
        String.to_atom(nextNode),
        {:forward, message <> " " <> nextNode, key, hopCount, listOfPids}
      )
    end
  
    def handle_cast({:forward, message, key, hopCount, listOfPids}, state) do
      selfKey = Atom.to_string(Process.info(self()) |> Enum.at(0) |> elem(1))
      route(message, key, selfKey, hopCount, state, listOfPids)
      {:noreply, state}
    end
  
    def handle_cast({:newRoutingTable, routingTable}, state) do
      state = List.replace_at(state, 1, routingTable)
      {:noreply, state}
    end
  
    def handle_cast({:sendMulticast, neighbourList}, state) do
      state = List.replace_at(state, 0, neighbourList)
  
      if(length(neighbourList) != 0) do
        updateRoutingTable(neighbourList, state)
      end
  
      {:noreply, state}
    end
  
    def handle_cast({:sendRequest, numRequests, listOfPids, x}, state) do
      sendMessages(numRequests, listOfPids, x, state)
      {:noreply, state}
    end
  
  
  end
  