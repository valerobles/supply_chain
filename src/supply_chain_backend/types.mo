import L "mo:base/List";

module {
    public type Supplier = {
        userName : Text;
        userId : Text; // TODO: change to type Principal?
    };
    public type Node = {

        //ID of the single Node
        nodeId : Nat;
        title : Text;
        owner : Supplier;
        nextOwner : Supplier; //Holds information to this node
        texts : [(Text, Text)];
        previousNodes : L.List<Node>;
        assetKeys : [(Text, Text)];
    };

    public type SupplierToDraftNodeID = {
        supplierID : Text;
        draftNodeID : Nat;
    };

    public type Chunk = {
        batch_name : Text;
        content : [Nat8];
    };

    public type CanisterSettings = {
        controllers : ?[Principal];
        compute_allocation : ?Nat;
        memory_allocation : ?Nat;
        freezing_threshold : ?Nat;
    };

    public type canister_id = Principal;

    // Management Canister Reference Methods
    public type Management = actor {

    create_canister : {
      settings : (s : CanisterSettings);
    } -> async { canister_id : canister_id };

    canister_status : { canister_id : canister_id } -> async {
      cycles : Nat;
      memory_size : Nat;
    };

    install_code : ({
      mode : { #install; #reinstall; #upgrade };
      canister_id : canister_id;
      wasm_module : Blob;
      arg : Blob;
    }) -> async ();

    stop_canister : { canister_id : canister_id } -> async ();

    delete_canister : { canister_id : canister_id } -> async ();

    deposit_cycles :  {canister_id : canister_id} -> ();

  };
};
