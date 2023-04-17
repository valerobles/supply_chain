import L "mo:base/List";

type Supplier = {
  userName : Text;
  userId : Text;
};
type Node = {
 
  //ID of the single Node
  nodeId : Nat;
  title : Text;
  owner : Supplier;
  nextOwner : Supplier; 
  //Holds information to this node
  //TODO key/value instead of one text
  texts : L.List<Text>;
  previousNodes : L.List<Node>;
};

