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

  //Creates a New node with n child nodes. Child nodes are given as a list of IDs in previousnodes.
  //CurrentOwner needs to be the same as "nextOwner" in the given childNodes to point to them.
  public func createLeafNode(previousNodes : List.List<Nat>, title : Text, currentOwner : T.Supplier) : async (Nat) {
    // Map Ids in previousNodes to actual nodes, add them to childNodes if owner is authorized
    var childNodes = List.filter<T.Node>(
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
    //Create the new node with a list of child nodes and other metadata
    let newNode = createNode(childNodes, title);

    allNodes := List.push<T.Node>(newNode, allNodes);
    nodeId;
  };

  //TODO next owner gets notified to create node containing this one and maybe others
  //Creates a new Node, increments nodeId BEFORE creating it.
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

  //returns all Nodes corresponding to their owner by Id
  public query func showNodesByOwnerId(id : Nat) : async Text {
    Utils.nodeListToText(Utils.getNodesByOwnerId(id, allNodes));
  };
  public query func showAllNodes() : async Text {
    Utils.nodeListToText(allNodes);
  };

  public query func showChildNodes(nodeId : Nat) : async Text {
    var output = "";
    var node = Utils.getNodeById(nodeId, allNodes);
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

  // Adds a new Supplier with to suppliers map with key = internet identity value = username
  // Only suppliers can add new suppliers. Exceptions for the first supplier added and the backend canister ID.
  // TODO Only admins can add suppliers
  public shared (message) func addSupplier(supplier : T.Supplier) : async Text {
    let caller = await getCaller();

    //FIXME CALLER==BACKENDCALLERID MIGHT BE SECURITY RISK. ONLY FOR TESTING
    // Exceptions for the first entry and if the caller is the backend canister. 
    // Suppliers can only be added  by authorized users. Existing IDs may not be overwritten
    if (suppliers.entries().next() == null or caller == backendCallerId or (suppliers.get(caller) != null and suppliers.get(supplier.userId) == null)) {
      suppliers.put(supplier.userId, supplier.userName);
      return "supplier with ID:"#supplier.userId#" Name:"#supplier.userName# "added";
    };

    return "Error: Request denied. Caller " #caller # " is not a supplier";
  };

  public query (message) func getCaller() : async Text {
    return Principal.toText(message.caller);
  };

};
