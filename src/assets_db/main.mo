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
import Time "mo:base/Time";
import Blob "mo:base/Blob";
import Error "mo:base/Error";
import Buffer "mo:base/Buffer";
import Bool "mo:base/Bool";
import Cycles "mo:base/ExperimentalCycles";


actor Main {
    
  private stable var storageWasm : [Nat8] = [];

  type CanisterSettings = {
    controllers : ?[Principal];
    compute_allocation : ?Nat;
    memory_allocation : ?Nat;
    freezing_threshold : ?Nat;
  };

  type canister_id = Principal;

  let IC = actor "aaaaa-aa" : actor {

    create_canister : {
      settings : (s : CanisterSettings);
    } -> async { canister_id : Principal };

    canister_status : { canister_id : Principal } -> async {
      // richer in ic.did
      cycles : Nat;
    };

    install_code : ({
      mode : { #install; #reinstall; #upgrade };
      canister_id : canister_id;
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

  public func create() : async () {

    let settings_ : CanisterSettings = {
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