import Principal "mo:base/Principal";
import T "./types";
import List "mo:base/List";
import Bool "mo:base/Bool";
import Array "mo:base/Array";

class Node(chainIdIn : Nat, nodeIdIn : Nat) {
  var isLast = false;
  //ID of the supply chain
  var chainId : Nat = chainIdIn;
  //ID of the single Node, maybe not needed?
  var nodeId : Nat = nodeIdIn;
  var title : Text = "";
  var owner : ?T.Supplier = null;
  //Holds information to this node 
  //TODO key/value instead of one text
  var texts = List.nil<Text>();
  var previousNodes = List.nil<Node>();

//Maybe belongs to utils/main?
 public func setNextNode(nextNode : Node, nextOwner : T.Supplier) {};
  //Add nodes pointing to this one
  public  func addPreviousNode(node : Node) {
    previousNodes := List.push<Node>(node, previousNodes);
  };
  //Add information as text to this node
  public func addText(text : Text) {
    texts := List.push<Text>(text, texts);
  };
};
