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
        //TODO key/value instead of one text
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
        content  : [Nat8];
    };

    public type CanisterSettings = {
        controllers : ?[Principal];
        compute_allocation : ?Nat;
        memory_allocation : ?Nat;
        freezing_threshold : ?Nat;
    };

    public type canister_id = Principal;

};
