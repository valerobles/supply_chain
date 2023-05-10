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

actor Main {

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

  //Creates a New node with n child nodes. Child nodes are given as a list of IDs in previousnodes.
  //CurrentOwner needs to be the same as "nextOwner" in the given childNodes to point to them.
  //previousNodes: Array of all child nodes. If the first elementdfx is "0", the list is assumed to be empty.
  public func createLeafNode(id:Nat,previousNodes : [Nat], title : Text, currentOwnerId : Text, nextOwnerId : Text) : async (Text) {

    let username = suppliers.get(currentOwnerId);
    let usernameNextOwner = suppliers.get(nextOwnerId);

    //Check if  next owner is null
    switch (usernameNextOwner) {
      case null { return "Error: Next owner not found." };
      case (?usernameNextOwner) {
        //Check if  current owner is null
        switch (username) {
          case null { return "Error: Logged in Account not found." };
          case (?username) {
            if (previousNodes[0] == 0) {
              Debug.print("ZERO");
              let newNode = createNode(id,List.nil(), title, { userId = currentOwnerId; userName = username }, { userId = nextOwnerId; userName = usernameNextOwner });
              allNodes := List.push<Types.Node>(newNode, allNodes);
              "Created node with ID: " #Nat.toText(nodeId);
            } else {
              // Map given Ids (previousNodes) to actual nodes, if they exist, they are added to childNodes
              //TODO maybe abort creation if one or more are not found?
              //Counter to keep track of amount of added nodes
              var c2 = 0;
              var childNodes = List.filter<Types.Node>(
                allNodes,
                func n {
                  var containsN = false;
                  for (i in Array.vals(previousNodes)) {
                    //Check if the node exists and if the currentOwner was defined as the nextOwner
                    if (n.nodeId == i and n.nextOwner.userId == currentOwnerId and n.nodeId <= nodeId) {
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
              for (i in Array.vals(previousNodes)) {
                c1 += 1;
              };

              //Check if all nodes were found
              if (c1 == c2) {
                //Create the new node with a list of child nodes and other metadata
                let newNode = createNode(id,childNodes, title, { userId = currentOwnerId; userName = username }, { userId = nextOwnerId; userName = usernameNextOwner });
                allNodes := List.push<Types.Node>(newNode, allNodes);
                "Created node with ID: " #Nat.toText(nodeId);
              } else {
                return "Error: Some Child IDs were invalid or missing ownership.";
              };
            };
          };
        };
      };
    };

  };

  //TODO next owner gets notified to create node containing this one and maybe others
  //Creates a new Node, increments nodeId BEFORE creating it.
  private func createNode(id : Nat, previousNodes : List.List<Types.Node>, title : Text, currentOwner : Types.Supplier, nextOwner : Types.Supplier) : (Types.Node) {

    {
      nodeId = id;
      title = title;
      owner = { userId = currentOwner.userId; userName = currentOwner.userName };
      nextOwner = { userId = nextOwner.userId; userName = nextOwner.userName };
      texts = List.nil<Text>();
      previousNodes = previousNodes;
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

        switch  (nodeListDrafts) {
          case null {
            
        };
          case ( ?nodeListDrafts) {
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

public query(message) func getDraftsBySupplier() : async [(Nat, Text)] {
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
    let a =  Buffer.toArray(listOfDraft);
    return a;
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

    return "Logged in as: " # Principal.toText(message.caller);
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
      return "supplier with ID:" #supplier.userId # " Name:" #supplier.userName # " added";
    };

    return "Error: Request denied. Caller " #caller # " is not a supplier";
  };

  public query (message) func getCaller() : async Text {
    return Principal.toText(message.caller);
  };

  // Chunking
  // Upload and download code was taken by dfinity's example project and was adapted to this project
  // https://github.com/carstenjacobsen/examples/tree/master/motoko/fileupload

  private var nextChunkID : Nat = 0;

  // hashmap of all the chunks uploaded to the backend canister
  // key: chunk ID
  // value: chunk
  private let chunks : HashMap.HashMap<Nat, Types.Chunk> = HashMap.HashMap<Nat, Types.Chunk>(
    0,
    Nat.equal,
    Hash.hash,
  );

  // hashmap of collection of chunks belonging to a file.
  // key: batch_name e.g. "nodeID/assets/fileName.png"
  // value: collection of chunks belonging together (type Asset)
  private let assets : HashMap.HashMap<Text, Types.Asset> = HashMap.HashMap<Text, Types.Asset>(
    0,
    Text.equal,
    Text.hash,
  );

  // puts the given chunk in the chunks hashmap together with the created chunkID. It then returns the chunkID as a record for frontend
  public func create_chunk(chunk : Types.Chunk) : async { chunk_id : Nat } {
    nextChunkID := nextChunkID + 1;
    chunks.put(nextChunkID, chunk);

    return { chunk_id = nextChunkID };
  };

  // This method is to collect the chunks content that belong together and saves it in the assets hashmap under thet batch_name(file name)
  public func commit_batch({
    batch_name : Text;
    chunk_ids : [Nat];
    content_type : Text;
  }) : async () {

    let content_chunks = Buffer.Buffer<[Nat8]>(4); //mutable array

    for (chunk_id in chunk_ids.vals()) {
      let chunk : ?Types.Chunk = chunks.get(chunk_id);

      switch (chunk) {
        case (?{ content }) {
          content_chunks.add(content);
        };
        case null {};
      };
    };

    if (content_chunks.size() > 0) {
      var total_length = 0;

      for (chunk in content_chunks.vals()) total_length += chunk.size();
      let content_chunks_array = Buffer.toArray(content_chunks);

      // assets hashmap takes as a key "assets/fileNameExample.png"
      assets.put(
        Text.concat("/assets/", batch_name),
        {
          content_type = content_type;
          encoding = {
            modified = Time.now();
            content_chunks = content_chunks_array;
            certified = false;
            total_length;
          };
        },
      );
    };
  };

  // handle GET requests for Files/Images
  // method is handles by Asset Canister interface
  // https://internetcomputer.org/docs/current/references/asset-canister/
  public query func http_request(
    request : Types.HttpRequest
  ) : async Types.HttpResponse {

    if (request.method == "GET") {
      Debug.print("incoming GET request");
      let split : Iter.Iter<Text> = Text.split(request.url, #char '?');
      let key : Text = Iter.toArray(split)[0]; //e.g. "/assets/fileName"

      // asset hashmap lookup
      let asset : ?Types.Asset = assets.get(key);

      switch (asset) {
        case (?{ content_type : Text; encoding : Types.AssetEncoding }) {
          return {
            body = encoding.content_chunks[0];
            headers = [
              ("Content-Type", content_type),
              ("accept-ranges", "bytes"),
              ("cache-control", "private, max-age=0"),
            ];
            status_code = 200;
            streaming_strategy = create_strategy(
              key,
              0,
              { content_type; encoding },
              encoding,
            );
          };
        };
        case null {};
      };
    };

    return {
      body = Blob.toArray(Text.encodeUtf8("Permission denied. Could not perform this operation"));
      headers = [];
      status_code = 403;
      streaming_strategy = null;
    };
  };

  // Creates a new token for the first chunk of content,
  // and then creates an actor reference of the Assets Canister to handle the streaming callback
  private func create_strategy(
    key : Text,
    index : Nat,
    asset : Types.Asset,
    encoding : Types.AssetEncoding,
  ) : ?Types.StreamingStrategy {
    switch (create_token(key, index, encoding)) {
      case (null) { null };
      case (?token) {
        let self : Principal = Principal.fromActor(Main);
        let canisterId : Text = Principal.toText(self);
        let canister = actor (canisterId) : actor {
          http_request_streaming_callback : shared () -> async ();
        }; // create actor reference

        return ?#Callback({
          token;
          callback = canister.http_request_streaming_callback;

        });
      };
    };
  };

  // //returns an HTTP response with the next chunk of content for the asset associated with the token
  // method is handled by the Asset Canister interface
  public query func http_request_streaming_callback(
    st : Types.StreamingCallbackToken
  ) : async Types.StreamingCallbackHttpResponse {

    switch (assets.get(st.key)) {
      case (null) throw Error.reject("key not found: " # st.key);
      case (?asset) {
        return {
          token = create_token(
            st.key,
            st.index,
            asset.encoding,
          );
          body = asset.encoding.content_chunks[st.index];
        };
      };
    };
  };

  // create a new streaming callback token for the next chunk of content
  private func create_token(
    key : Text,
    chunk_index : Nat,
    encoding : Types.AssetEncoding,
  ) : ?Types.StreamingCallbackToken {
    if (chunk_index + 1 >= encoding.content_chunks.size()) {
      null;
    } else {
      ?{
        key;
        index = chunk_index + 1;
        content_encoding = "gzip";
      };
    };
  };

};
