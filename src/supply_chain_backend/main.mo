import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Types "./types";
import Nat "mo:base/Nat";
import Map "mo:base/HashMap";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import List "mo:base/List";
import Utils "utils";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Time "mo:base/Time";
import Blob "mo:base/Blob";
import Error "mo:base/Error";
import Buffer "mo:base/Buffer";
import DraftNode "draftNode";
import Bool "mo:base/Bool";
import Prim "mo:prim";
import Cycles "mo:base/ExperimentalCycles";

actor Main {

  private stable var storageWasm : [Nat8] = [];
  stable var canister_ids = List.nil<Text>();

  //Learning: Cant return non-shared classes (aka mutable classes). Save mutable data to this actor instead of node?
  var allNodes = List.nil<Types.Node>(); // make stable

  var nodeId : Nat = 0; // make stable
  func natHash(n : Text) : Hash.Hash {
    Text.hash(n);
  };
  //Contains all registered suppliers
  var suppliers = Map.HashMap<Text, Text>(0, Text.equal, natHash);

  // Contains all the drafts of each Supplier. Mapping from Supplier Id to a List of all Drafts
  var supplierToDraftNodeID = HashMap.HashMap<Text, List.List<DraftNode.DraftNode>>(0, Text.equal, natHash);

  private func removeDraft(id : Nat, caller : Text) {
    let drafts = supplierToDraftNodeID.get(caller);
    switch (drafts) {
      case null {};
      case (?drafts) {
        let newList = List.filter<DraftNode.DraftNode>(drafts, func n { not (n.id == id) });
        supplierToDraftNodeID.put(caller, newList);
      };
    };

  };
  //Creates a New node with n child nodes. Child nodes are given as a list of IDs in previousnodes.
  //CurrentOwner needs to be the same as "nextOwner" in the given childNodes to point to them.
  //previousNodes: Array of all child nodes. If the first elementdfx is "0", the list is assumed to be empty.
  public shared (message) func createLeafNode(draftId : Nat) : async (Text, Bool) {
    let caller = Principal.toText(message.caller);
    let draft = getDraftByIdAsObject(draftId, caller);
    let owner = draft.owner;
    let username = suppliers.get(draft.owner.userId);
    let usernameNextOwner = suppliers.get(draft.nextOwner.userId);

    //Check if  next owner is null
    switch (usernameNextOwner) {
      case null { return ("Error: Next owner not found.", false) };
      case (?usernameNextOwner) {
        //Check if  current owner is null
        switch (username) {
          case null { return ("Error: Logged in Account not found.", false) };
          case (?username) {
            if (draft.previousNodesIDs[0] == 0) {
              Debug.print("ZERO");
              let newNode = createNode(draft.id, List.nil(), draft.title, draft.owner, draft.nextOwner, draft.labelToText, draft.assetKeys);
              allNodes := List.push<Types.Node>(newNode, allNodes);
              removeDraft(draft.id, caller);
              ("Finalized node with ID: " #Nat.toText(draft.id), true);
            } else {
              // Map given Ids (previousNodes) to actual nodes, if they exist, they are added to childNodes
              //TODO maybe abort creation if one or more are not found?
              //Counter to keep track of amount of added nodes
              var c2 = 0;
              var childNodes = List.filter<Types.Node>(
                allNodes,
                func n {
                  var containsN = false;
                  for (i in Array.vals(draft.previousNodesIDs)) {
                    //Check if the node exists and if the currentOwner was defined as the nextOwner
                    if (n.nodeId == i and n.nextOwner.userId == draft.owner.userId and n.nodeId <= nodeId) {
                      // and n.nodeId!=nodeId+1
                      containsN := true;
                      c2 += 1;
                    };
                  };

                  containsN;
                },
              );
              //Counter for original amount of childnodes
              var c1 = 0;
              for (i in Array.vals(draft.previousNodesIDs)) {
                c1 += 1;
              };

              //Check if all nodes were found
              if (c1 == c2) {
                //Create the new node with a list of child nodes and other metadata
                let newNode = createNode(draft.id, childNodes, draft.title, draft.owner, draft.nextOwner, draft.labelToText, draft.assetKeys);
                allNodes := List.push<Types.Node>(newNode, allNodes);
                removeDraft(draft.id, caller);
                ("Finalized node with ID: " #Nat.toText(draft.id), true);
              } else {
                return ("Error: Some Child IDs were invalid or missing ownership.", false);
              };
            };
          };
        };
      };
    };

  };

  //TODO next owner gets notified to create node containing this one and maybe others
  //Creates a new Node, increments nodeId BEFORE creating it.
  private func createNode(id : Nat, previousNodes : List.List<Types.Node>, title : Text, currentOwner : Types.Supplier, nextOwner : Types.Supplier, labelToText : [(Text, Text)], assetKeys : [Text]) : (Types.Node) {

    {
      nodeId = id;
      title = title;
      owner = { userId = currentOwner.userId; userName = currentOwner.userName };
      nextOwner = { userId = nextOwner.userId; userName = nextOwner.userName };
      texts = labelToText;
      previousNodes = previousNodes;
      assetKeys = assetKeys;
    };
  };

  // Creates a DraftNode object. It takes nodeId and the owner.
  // with the created DraftNode object, it is added to the supplierToDraftNodeID Hashmap as a List
  // that manages the supplier to all of their drafts
  public shared (message) func createDraftNode(title : Text) : async Text {
    nodeId += 1;

    let ownerId = Principal.toText(message.caller);
    // assert not Principal.isAnonymous(message.caller);
    let ownerName = suppliers.get(ownerId);

    switch (ownerName) {
      case null {
        return "Error: You are not a supplier";
      };
      case (?ownerName) {

        let node = DraftNode.DraftNode(nodeId, { userName = ownerName; userId = ownerId }, title);
        let nodeListDrafts = supplierToDraftNodeID.get(ownerId);
        var tempList = List.nil<DraftNode.DraftNode>();

        switch (nodeListDrafts) {
          case null {

          };
          case (?nodeListDrafts) {
            tempList := nodeListDrafts;
          };
        };
        tempList := List.push<DraftNode.DraftNode>(node, tempList);
        supplierToDraftNodeID.put(ownerId, tempList);
        return "Draft succesfully created";
      };
    };

  };

  //returns all Nodes corresponding to their owner by Id
  public query func showNodesByOwnerId(id : Text) : async Text {
    Utils.nodeListToText(Utils.getNodesByOwnerId(id, allNodes));
  };
  public query func showAllNodes() : async Text {
    Utils.nodeListToText(allNodes);
  };

  //Returns all information of a node excluding id/childnodes
  //Values are all empty if node does not exist
  public query func getNodeById(id : Nat) : async (Text, Types.Supplier, Types.Supplier, [(Text, Text)], [Text]) {
    let node = Utils.getNodeById(id, allNodes);
    switch (node) {
      case null {
        ("", { userName = ""; userId = "" }, { userName = ""; userId = "" }, [("", "")], [""]);
      };
      case (?node) {
        return (node.title, node.owner, node.nextOwner, node.texts, node.assetKeys);
      };
    };

  };

  public query func checkNodeExists(id : Nat) : async (Bool) {
    let node = Utils.getNodeById(id, allNodes);
    switch (node) {
      case null {
        false;
      };
      case (?node) {
        return true;
      };
    };

  };

  public query (message) func isSupplierLoggedIn() : async Bool {
    let ownerId = Principal.toText(message.caller);
    if (suppliers.get(ownerId) == null) {
      return false;
    } else {
      return true;
    };
  };

  public query (message) func canAddNewSupplier() : async Bool {
    let ownerId = Principal.toText(message.caller);
    if (suppliers.get(ownerId) != null or suppliers.size() == 0) {
      return true;
    } else {
      return false;
    };
  };

  public shared (message) func saveToDraft(nodeId : Nat, nextOwner : Types.Supplier, labelToText : [(Text, Text)], previousNodes : [Nat], assetKeys : [Text]) : async (Text) {
    let ownerId = Principal.toText(message.caller);
    // assert not Principal.isAnonymous(message.caller);
    assert not (suppliers.get(ownerId) == null);
    var draftList = supplierToDraftNodeID.get(ownerId);

    switch (draftList) {
      case null {
        return "no draft found under this supplier";
      };
      case (?draftList) {

        let draftTemp = List.find<DraftNode.DraftNode>(
          draftList,
          func draft {
            nodeId == draft.id;
          },
        );

        switch (draftTemp) {
          case null {
            return "no draft node found under given ID";
          };
          case (?draftTemp) {
            draftTemp.nextOwner := nextOwner;
            draftTemp.labelToText := labelToText;
            draftTemp.previousNodesIDs := previousNodes;
            draftTemp.assetKeys := assetKeys;
            return " Draft successfully saved";
          };
        };

      };
    };
    return "Something went wrong";

  };

  public query (message) func getDraftsBySupplier() : async [(Nat, Text)] {
    let ownerId = Principal.toText(message.caller);
    var draftList = supplierToDraftNodeID.get(ownerId);
    let listOfDraft = Buffer.Buffer<(Nat, Text)>(1);
    switch (draftList) {
      case null {
        // listOfDraft.add((0, ""));
      };
      case (?draftList) {
        List.iterate<DraftNode.DraftNode>(draftList, func d { listOfDraft.add((d.id, d.title)) });

      };

    };
    return Buffer.toArray(listOfDraft);
  };
  public query (message) func getDraftById(id : Nat) : async (Nat, Text, Types.Supplier, [(Text, Text)], [Nat], [Text]) {
    let ownerId = Principal.toText(message.caller);
    var draftList = supplierToDraftNodeID.get(ownerId);
    let emptyDraft = (0, "", { userName = ""; userId = "" }, [("", "")], [0], [""]);
    switch (draftList) {
      case null {
        return emptyDraft;
      };
      case (?draftList) {
        let d = List.find<DraftNode.DraftNode>(draftList, func draft { draft.id == id });
        switch (d) {
          case null {};
          case (?d) {
            return (d.id, d.title, d.nextOwner, d.labelToText, d.previousNodesIDs, d.assetKeys);
          };
        };
      };

    };
    return emptyDraft;
  };
  private func getDraftByIdAsObject(id : Nat, ownerId : Text) : DraftNode.DraftNode {

    var draftList = supplierToDraftNodeID.get(ownerId);
    let emptyDraft = DraftNode.DraftNode(0, { userName = ""; userId = "" }, "");
    switch (draftList) {
      case null {
        return emptyDraft;
      };
      case (?draftList) {
        let d = List.find<DraftNode.DraftNode>(draftList, func draft { draft.id == id });
        switch (d) {
          case null {};
          case (?d) {
            return d;
          };
        };
      };

    };
    return emptyDraft;
  };

  //Recursive function to append all child nodes of a given Node by ID.
  //Returns dependency structure as a text
  private func showChildNodes(nodeId : Nat, level : Text) : (Text) {
    var output = "";
    var node = Utils.getNodeById(nodeId, allNodes);
    switch (node) {
      case null { output := "Error: Node not found" };
      case (?node) {
        List.iterate<Types.Node>(
          node.previousNodes,
          func n {
            output := output # "\n" #level # "ID: " #Nat.toText(n.nodeId) # " Title: " #n.title;
            let childNodes = n.previousNodes;
            switch (childNodes) {
              case (null) {};
              case (?nchildNodes) {
                output := output #showChildNodes(n.nodeId, level # "----");
              };
            };
          },
        );
      };
    };
    output;
  };
  public query func showAllChildNodes(nodeId : Nat) : async Text {
    showChildNodes(nodeId, "");
  };

  public query (message) func greet() : async Text {
    let id = Principal.toText(message.caller);
    let sup = suppliers.get(id);

    switch (sup) {
      case null {
        return "Logged in with ID: " # id;
      };
      case (?sup) {
        return "Logged in as: " # sup # "\n Logged in with ID: " # id;
      };
    };

  };

  public query func getSuppliers() : async [Text] {
    Iter.toArray(suppliers.vals());
  };

  // Adds a new Supplier with to suppliers map with key = internet identity value = username
  // Only suppliers can add new suppliers. Exceptions for the first supplier added and the backend canister ID.
  // TODO Only admins can add suppliers
  public shared (message) func addSupplier(supplier : Types.Supplier) : async Text {
    let caller = Principal.toText(message.caller);

    // Exceptions for the first entry and if the caller is the backend canister.
    // Suppliers can only be added  by authorized users. Existing IDs may not be overwritten

    if ((suppliers.size() == 0 or suppliers.get(caller) != null) and suppliers.get(supplier.userId) == null) {
      suppliers.put(supplier.userId, supplier.userName);
      return "supplier added with\nID: " #supplier.userId # "\nName: " #supplier.userName;
    };

    return "Error: Request denied. Caller " #caller # " is not a supplier";
  };

  public query (message) func getCaller() : async Text {
    return Principal.toText(message.caller);
  };

  
  canister_ids := List.push<Text>("bkyz2-fmaaa-aaaaa-qaaaq-cai", canister_ids);

  let IC = actor "aaaaa-aa" : actor {

    // TODO add method that checks memory availability

    create_canister : {
      settings : (s : Types.CanisterSettings);
    } -> async { canister_id : Principal };

    canister_status : { canister_id : Principal } -> async {
      cycles : Nat;
    };

    install_code : ({
      mode : { #install; #reinstall; #upgrade };
      canister_id : Types.canister_id;
      wasm_module : Blob;
      arg : Blob;
    }) -> async ();

    stop_canister : { canister_id : Principal } -> async ();

    delete_canister : { canister_id : Principal } -> async ();
  };

  public func storageLoadWasm(blob : [Nat8]) : async ({
    total : Nat;
    chunks : Nat;
  }) {

    let buffer : Buffer.Buffer<Nat8> = Buffer.fromArray<Nat8>(storageWasm);
    let chunks : Buffer.Buffer<Nat8> = Buffer.fromArray<Nat8>(blob);
    buffer.append(chunks);
    storageWasm := Buffer.toArray(buffer);
    Debug.print(Nat.toText(storageWasm.size()));

    return {
      total = storageWasm.size();
      chunks = blob.size();
    };
  };

  public shared (message) func create() : async () {

    let settings_ : Types.CanisterSettings = {
      controllers = ?[Principal.fromActor(Main), message.caller];
      compute_allocation = null;
      memory_allocation = null;
      freezing_threshold = null;
    };

    Cycles.add(Cycles.balance() / 2);
    let cid = await IC.create_canister({ settings = settings_ });
    Debug.print("canister id " # Principal.toText(cid.canister_id));
    canister_ids := List.push<Text>(Principal.toText(cid.canister_id), canister_ids);
    let status = await IC.canister_status(cid);
    Debug.print("canister " #Principal.toText(cid.canister_id) # " has " # Nat.toText(status.cycles) # " cycles");

    await IC.install_code({
      mode = #install;
      canister_id = cid.canister_id;
      wasm_module = Blob.fromArray(storageWasm);
      arg = Blob.fromArray([]);
    });

  };

  var asset_canisters = List.nil<Types.Asset_Canister>();

  let AC : Types.Asset_Canister = actor ("b77ix-eeaaa-aaaaa-qaada-cai");

  asset_canisters := List.push<Types.Asset_Canister>(AC, asset_canisters);

  public query func getAvailableAssetsCanister() : async ?Text {
    // TODO
    // add logic to find available Canister for upload
    // if none available, create new canister
    let size : Nat = List.size<Text>(canister_ids);
    Debug.print(Nat.toText(size));
  
    return List.get<Text>(canister_ids,0);
  };

  // public func create_chunk(chunk : Types.Chunk, asset_canister_id : Text) : async {
  //   chunk_id : Nat;
  // } {

  //   return await AC.create_chunk(chunk);

  // };

  // public func commit_batch({
  //   node_id : Nat;
  //   batch_name : Text;
  //   chunk_ids : [Nat];
  //   content_type : Text;
  // }) : async () {
  //   await AC.commit_batch({
  //     node_id;
  //     batch_name;
  //     chunk_ids;
  //     content_type;
  //   });

  // };

};
