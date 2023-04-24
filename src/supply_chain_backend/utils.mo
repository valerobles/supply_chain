import T "./types";
import List "mo:base/List";
import Nat "mo:base/Nat";

module Utils {
   public func getNodeById(id : Nat, allNodes : List.List<T.Node>) : (?T.Node) {
    List.find<T.Node>(allNodes, func n { n.nodeId == id });
  };
   public func getNodesByOwnerId(id : Text, allNodes : List.List<T.Node>) : (List.List<T.Node>) {
    var nodeList = List.nil<T.Node>();
    List.iterate<T.Node>(allNodes, func n { if (n.owner.userId == id) { nodeList := List.push<T.Node>(n, nodeList) } });
    nodeList;
  };
  public func nodeListToText(list : List.List<T.Node>) : Text {
    var output = "";
    List.iterate<T.Node>(list, func n { output := output # "\nID: " #Nat.toText(n.nodeId) # " Title: " #n.title });
    output;
  };
 
};
