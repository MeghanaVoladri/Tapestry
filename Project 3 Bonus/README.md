## Team

Bhasanth Lakkaraju UFID: 41602287
Meghana Reddy Voladri UFID: 43614999

## Working
We have implemented the network join and routing as described in the paper. When the user enters the total number of nodes, we are creating 90% of the input nodes at a time and the remaining 10% of the nodes are added to the network using the join function. Once we have the hash value of the new node to be joined, we are comparing it with all the existing nodes in the network and choosing the nodes with largest matching prefix. Once we have the list of the closest nodes, we call these as the neighbor set and the routing tables of the nodes in the neighbor set are updated by adding the new node to be joined ( as there is a prefix match and the new node will have an entry in these nodes’ routing tables). It will be a better approach to copy the routing tables of one of these neighbor sets as the routing table would almost be same up to some levels (length of the matched prefix). We choose the node that is closest among the neighbor set entries and copy the routing table of that node until the levels matched. Later, we calculate the remaining rows of the routing table. Based on the routing table, nodes are routed to their respective nearby nodes.

## Largest Networks

We have checked this implementation for upto 3000 nodes with 1-20 requests.