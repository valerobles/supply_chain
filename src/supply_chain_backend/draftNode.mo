import Types "./types";
import Text "mo:base/Text";
import List "mo:base/List";


class DraftNode(id_: Nat, owner_ : Types.Supplier, title_ : Text) {
    public let id = id_;
    public let owner = owner_;
    public let title: Text = title_;
    public var nextOwner: Types.Supplier = {userName = ""; userId = ""};
    public var labelToText : [(Text,Text)] = [("Label","Text")];
    public var previousNodesIDs: [Nat] = [0];
    // nodeId/assets/fileName.png -> canisterId
    public var assetKeys : [(Text,Text)] = [];
}

