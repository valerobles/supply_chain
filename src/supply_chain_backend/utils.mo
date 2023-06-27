import Types "./types";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Bool "mo:base/Bool";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Debug "mo:base/Debug";
import DraftNode "draftNode";

module Utils {
  public func get_node_by_id(id : Nat, allNodes : List.List<Types.Node>) : (?Types.Node) {
    List.find<Types.Node>(allNodes, func n { n.nodeId == id });
  };

  public func node_exists(id : Nat, allNodes : List.List<Types.Node>) : (Bool) {
    let node = get_node_by_id(id, allNodes);
    switch (node) {
      case null {
        false;
      };
      case (?node) {
        return true;
      };
    };
  };

  public func nodeListToText(list : List.List<Types.Node>) : Text {
    var output = "";
    List.iterate<Types.Node>(list, func n { output := output # "\nID: " #Nat.toText(n.nodeId) # " Title: " #n.title });
    output;
  };

  public func is_supplier_logged_in(ownerId : Text, suppliers : HashMap.HashMap<Text, Text>) : Bool {
    if (suppliers.get(ownerId) == null) {
      return false;
    } else {
      return true;
    };
  };

  public func can_add_new_supplier(ownerId : Text, suppliers : HashMap.HashMap<Text, Text>) : Bool {
    if (suppliers.get(ownerId) != null or suppliers.size() == 0) {
      return true;
    } else {
      return false;
    };
  };

  public func get_draft_by_id(nodeId : Nat, caller : Text, supplierToDraftNodeID : HashMap.HashMap<Text, List.List<DraftNode.DraftNode>>)
   : ?DraftNode.DraftNode {

    // Get list of drafts belonging to the caller 
    var draftList = supplierToDraftNodeID.get(caller);

    switch (draftList) {
      case null {
        return null;
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
            return null;
          };
          case (?draftTemp) {
            return ?draftTemp;
          };
        };

      };

    };

  };

};
