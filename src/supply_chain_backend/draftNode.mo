import Types "./types";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import List "mo:base/List";


class DraftNode(id_: Nat, owner_ : Types.Supplier) {


    func natHash(n : Text) : Hash.Hash {
        Text.hash(n);
  };

    public var id = id_;
    public var owner = owner_;
    public let title: Text = "";
    public let nextOwner: Types.Supplier = {userName = ""; userId = ""};
    public let labelToText = HashMap.HashMap<Text, Text>(0, Text.equal, natHash);

    public let previousNodesIDs = List.nil<Nat>();

    public let assetKeys = List.nil<Text>();


}

