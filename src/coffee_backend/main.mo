import Principal "mo:base/Principal";
import Array "mo:base/Array";
import T "./types";
import Nat "mo:base/Nat";
import Map "mo:base/HashMap";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import List "mo:base/List";
import Utils "utils";
actor class Main() {
  //Learning: Cant return non-shared classes (aka mutable classes). Save mutable data to this actor instead of node?
  var allNodes = List.nil<T.Node>(); // make stable

  var nodeId : Nat = 0; // make stable
  func natHash(n : Text) : Hash.Hash {
    Text.hash(n);
  };
  //Contains all registered suppliers
  var suppliers = Map.HashMap<Text, Text>(0, Text.equal, natHash);
  //Creates a new chain and returns the first node id.
  public func createRootNode(title : Text) : async (Nat) {

    let newNode = createNode(List.nil<T.Node>(), title);
  
    allNodes := List.push<T.Node>(newNode, allNodes);
    nodeId;
  };

  //TODO remove previousNodes that were used from allNodes
  public func createLeafNode(previousNodes : List.List<Nat>, title : Text, currentOwner : T.Supplier) : async (Nat) {
    // Create a list of all Previous nodes given as a param that actually exist and point to the right owner.
    var l = List.filter<T.Node>(
      allNodes,
      func n {
        var containsN = false;
        for (i in List.toIter<Nat>(previousNodes)) {
          if (n.nodeId == i and n.nextOwner.userId == currentOwner.userId) {
            containsN := true;
          };
        };
        containsN;
      },
    );

    let newNode = createNode(l, title);
    allNodes := List.push<T.Node>(newNode, allNodes);
    nodeId;
  };

   //TODO next owner gets notified to create node containing this one and maybe others
  private func createNode(previousNodes : List.List<T.Node>, title : Text) : (T.Node) {
    nodeId += 1;
    {
      nodeId = nodeId;
      title = title;
      // isLast = false;
      owner = { userId = "test"; userName = "test" };
      nextOwner = { userId = "test"; userName = "test" };
      texts = List.nil<Text>();
      previousNodes = previousNodes;
    };
  };

  public query func showNodesByOwnerId(id : Nat) : async Text {
    Utils.nodeListToText(Utils.getNodesByOwnerId(id,allNodes));
  };
  public query func showAllNodes() : async Text {
    Utils.nodeListToText(allNodes);
  };

  public query func showChildNodes(nodeId : Nat) : async Text {
    var output = "";
    var node = Utils.getNodeById(nodeId,allNodes);
    switch (node) {
      case null { output := "Error: Node not found" };
      case (?node) {
        List.iterate<T.Node>(node.previousNodes, func n { output := output # "\nID: " #Nat.toText(n.nodeId) # " Title: " #n.title });
      };
    };
    output;
  };

  public query (message) func greet() : async Text {

    return "Logged in as: " # Principal.toText(message.caller);
  };

  public query func getSuppliers() : async [Text] {
    Iter.toArray(suppliers.vals());
  };

  let backendCallerId = "rrkah-fqaaa-aaaaa-aaaaq-cai";
  // Returns the ID that was given to the Supplier
  public shared (message) func addSupplier(supplier : T.Supplier) : async Text {
    // let caller = Principal.toText(message.caller);
    let caller = await getCaller();
    //FIXME CALLER==BACKENDCALLERID MIGHT BE SECURITY RISK, MAYBE ONLY FOR TESTING
    if (suppliers.entries().next() == null or suppliers.get(caller) != null or caller == backendCallerId) {
      suppliers.put(supplier.userId, supplier.userName);
      return "supplier added";
    };

    return "Error: Request denied. Caller " #caller # " is not a supplier";
  };

  public query (message) func getCaller() : async Text {
    return Principal.toText(message.caller);
  };

  // Getting Caller Test
  public shared (msg) func addSupplierT(userName : Text) : async Text {

    suppliers.put(Principal.toText(msg.caller), userName);
    return "supplier added" # Principal.toText(msg.caller) # ".";

  };

  public shared (msg) func getCallerT() : async Text {
    return Principal.toText(msg.caller);
  };

};
