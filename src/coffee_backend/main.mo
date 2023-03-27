import Principal "mo:base/Principal";
import Array "mo:base/Array";
import T "./types";
import Nat "mo:base/Nat";
import Map "mo:base/HashMap";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import List "mo:base/List";
import N "./node";

actor class Main() {

  var starterNodes = List.nil<N.Node>();
  var chainId : Nat = 0;
  var nodeId : Nat = 0;

//Creates a new chain and returns the first node
  public func createChain() : async (N.Node) {
    chainId += 1;
    nodeId += 1;
    let newNode = N.Node(chainId, nodeId);
    starterNodes := List.push<N.Node>(newNode, starterNodes);
    newNode;
  };

  public func appendPreviousNode(nodeFront : N.Node, nodeBack : N.Node) : async(){
    nodeFront.addPreviousNode(nodeBack);
  };

  public query (message) func greet() : async Text {

    return "Hello, " # Principal.toText(message.caller) # "!";
  };

  func natHash(n : Text) : Hash.Hash {
    Text.hash(n);
  };
  //Contains all registered suppliers
  var suppliers = Map.HashMap<Text, Text>(0, Text.equal, natHash);

  public query func getSuppliers() : async [Text] {
    Iter.toArray(suppliers.vals());
  };

  //FIXME getCaller() doesn't returns coffee_backend canister Id instead of user id
  // Returns the ID that was given to the Supplier
  public func addSupplier(supplier : T.Supplier) : async Text {
    // let caller = Principal.toText(message.caller);
    let caller = await getCaller();
    if (suppliers.entries().next() == null or suppliers.get(caller) != null) {
      suppliers.put(supplier.userID, supplier.userName);
      return "supplier added";
    };

    return "caller " #caller # " is not a supplier";
  };

  public query (message) func getCaller() : async Text {
    return Principal.toText(message.caller);
  };

  // public query func showSuppliers() : async Text {
  //   var output : Text = "\n___Suppliers___";
  //   for (supplier : T.Supplier in suppliers.vals()) {
  //     output #= "\n" # supplier.userName;
  //     output #= "\n" # supplier.userID;
  //   };
  //   output # "\n"
  // };

};
