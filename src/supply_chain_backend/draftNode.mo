import Types "./types";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import List "mo:base/List";


class DraftNode(id_: Nat, owner_ : Types.Supplier, title_ : Text) {


    func natHash(n : Text) : Hash.Hash {
        Text.hash(n);
  };

    public let id = id_;
    public let owner = owner_;
    public let title: Text = title_;

    public var nextOwner: Types.Supplier = {userName = ""; userId = ""};
    public var labelToText : [(Text,Text)] = [("Label","Text")];

    public var previousNodesIDs: [Nat] = [0];

    //e.g. id/assets/fileName.png
    public var assetKeys : [Text] = [];




}

