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

    public var nextOwner: Types.Supplier = {userName = "luca"; userId = "89"};
    public var labelToText : [(Text,Text)] = [("Testtitle","mytext")];

    public var previousNodesIDs: [Nat] = [1,2,3];

    public var assetKeys : [Text] = [];




}

