import L "mo:base/List";

type Supplier = {
  userName : Text;
  userId : Text;
};
type Node = {
 
  //ID of the supply chain
  //chainId : Nat;
  //ID of the single Node, maybe not needed?
  nodeId : Nat;
  title : Text;
 // isLast : Bool;
  owner : Supplier;
  nextOwner : Supplier; // val: TODO can be multiple
  //Holds information to this node
  //TODO key/value instead of one text
  texts : L.List<Text>;
  previousNodes : L.List<Node>;
};

