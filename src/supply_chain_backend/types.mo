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
        assetKeys : [Text];
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

    public type Asset_Canister = actor {

        get_my_canister_id : () -> async (Text);


        create_chunk : (
            chunk : Chunk
        ) -> async { chunk_id : Nat };

        commit_batch : ({
            node_id : Nat;
            batch_name : Text;
            chunk_ids : [Nat];
            content_type : Text;
        }) -> async ();

    };
};
