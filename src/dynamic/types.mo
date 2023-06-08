import Principal "mo:base/Principal";
import Text "mo:base/Text";

type CanisterSettings = {
  controllers : Principal;
  compute_allocation : ?Nat;
  memory_allocation : ?Nat;
  freezing_threshold :?Nat;
};

type canister_id = Principal;