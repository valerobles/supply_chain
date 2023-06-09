import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Map "mo:base/HashMap";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import List "mo:base/List";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Types "types";
import Time "mo:base/Time";

actor Main {

    private stable var storageWasm : [Nat8] = [];

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
    node_id : Nat;
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

      // assets hashmap takes as a key "nodeId/assets/fileNameExample.png"
      assets.put(
        "/" # Nat.toText(node_id) # "/assets/" # batch_name,
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


    let IC = actor "aaaaa-aa" : actor {

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

    public query func greet() : async () {
        Debug.print("Hello from Assets Canister");
    };

    public func create() : async () {

        let settings_ : Types.CanisterSettings = {
            controllers = ?[Principal.fromActor(Main)];
            compute_allocation = null;
            memory_allocation = null;
            freezing_threshold = null;
        };

        Cycles.add(Cycles.balance() / 2);
        let cid = await IC.create_canister({ settings = settings_ });
        Debug.print("canister id " # Principal.toText(cid.canister_id));
        let status = await IC.canister_status(cid);
        Debug.print("canister " #Principal.toText(cid.canister_id) # " has " # Nat.toText(status.cycles) # " cycles");

        await IC.install_code({
            mode = #install;
            canister_id = cid.canister_id;
            wasm_module = Blob.fromArray(storageWasm);
            arg = Blob.fromArray([]);
        });

    };

};
