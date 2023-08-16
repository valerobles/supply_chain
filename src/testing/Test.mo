import Canister "canister:supply_chain_backend";
import C "../testing/matchers/Canister";
import M "../testing/matchers/Matchers";
import T "../testing/matchers/Testable";
import Nat "mo:base/Nat";
//import D "../supply_chain_backend/draftNode";

actor {
  let it = C.Tester({ batchSize = 5 });
  let testUser = { userId = "b77ix-eeaaa-aaaaa-qaada-cai"; userName = "Test" };
  public shared func test() : async Text {
    let register = await Canister.add_supplier(testUser);

    it.should(
      "Check login",
      func() : async C.TestResult = async {
        let greeting = await Canister.greet();
        M.attempt(greeting, M.equals(T.text("Logged in as: " #testUser.userName # "\n Logged in with ID: " #testUser.userId)));
      },
    );

    it.should(
      "Create draft and check id",
      func() : async C.TestResult = async {
        var id = await Canister.get_current_node_id();
        id := id +1;
        let result = await Canister.create_draft_node("Mydraft");
        M.attempt(result, M.equals(T.text("Draft with id: " #Nat.toText(id) # " succesfully created")));
      },
    );
    it.should(
      "Create draft, change title and finalize",
      func() : async C.TestResult = async {
        var id = await Canister.get_current_node_id();
        id := id +1;
        let draft = await Canister.create_draft_node("Mydraft");
        let d = await Canister.save_draft(id, "NewTitle", testUser, [], [0], []);
        let result = await Canister.create_leaf_node(id);
        M.attempt(result.0, M.equals(T.text("Finalized node with ID: " #Nat.toText(id))));
      },
    );
    it.should(
      "Create and get draft by id",
      func() : async C.TestResult = async {
        var id = await Canister.get_current_node_id();
        id := id +1;
        let draft = await Canister.create_draft_node("CreateAndGetDraft");
        let result = await Canister.get_draft_by_id(id);

        M.attempt(result.1, M.equals(T.text("CreateAndGetDraft")));

      },
    );
    it.should(
      "Get empty draft",
      func() : async C.TestResult = async {

        let result = await Canister.get_draft_by_id(9999);

        M.attempt(result.1, M.equals(T.text("")));

      },
    );
    await it.runAll();
    // await it.run();
  };

};
