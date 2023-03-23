import Principal "mo:base/Principal";
import Array "mo:base/Array";
import T "./types";
import Nat "mo:base/Nat";
import Map "mo:base/HashMap";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Text "mo:base/Text";

shared (message) actor class Main() {

 
  public query func greet() : async Text {
  
    return "Hello, " # Principal.toText(message.caller) # "!";
  };


  func natHash(n : Nat) : Hash.Hash { 
    Text.hash(Nat.toText(n))
  };

  var suppliers = Map.HashMap<Nat, T.Supplier>(0, Nat.equal, natHash);
  var nextId : Nat = 0;

  public query func getSuppliers() : async [T.Supplier] {
    Iter.toArray(suppliers.vals());
  };

  // Returns the ID that was given to the ToDo item
  public func addSupplier(userName : Text, userID : Text) : async Nat {
    let id = nextId;
    suppliers.put(id, { userName = userName; userID = userID });
    nextId += 1;
    return id
  };

 

  public query func showSuppliers() : async Text {
    var output : Text = "\n___Suppliers___";
    for (supplier : T.Supplier in suppliers.vals()) {
      output #= "\n" # supplier.userName;
      output #= "\n" # supplier.userID;
    };
    output # "\n"
  };

};
