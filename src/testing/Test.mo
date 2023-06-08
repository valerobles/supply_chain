import Canister "canister:supply_chain_backend";
import C "../testing/matchers/Canister";
import M "../testing/matchers/Matchers";
import T "../testing/matchers/Testable";
import Nat "mo:base/Nat";
import D "../supply_chain_backend/draftNode";

actor {
  let it = C.Tester({ batchSize = 8 });

  public shared func test() : async Text {

    let register = await Canister.addSupplier({
      userId = "rno2w-sqaaa-aaaaa-aaacq-cai";
      userName = "Test";
    });

    it.should(
      "Check login",
      func() : async C.TestResult = async {
        let greeting = await Canister.greet();
        M.attempt(greeting, M.equals(T.text("Logged in as: rno2w-sqaaa-aaaaa-aaacq-cai")));
      },
    );

    it.should(
      "Create draft and check id",
      func() : async C.TestResult = async {
        var id = await Canister.getCurrentNodeId();
        id := id +1;
        let result = await Canister.createDraftNode("Mydraft");

        M.attempt(result, M.equals(T.text("Draft with id: " #Nat.toText(id) # " succesfully created")));

      },
    );
    it.should(
      "Finalize node",
      func() : async C.TestResult = async {
        var id = await Canister.getCurrentNodeId();
        id := id +1;
        let draft = await Canister.createDraftNode("Mydraft");
        let result = await Canister.createLeafNode(id);

        M.attempt(result.0, M.equals(T.text("Finalized node with ID: " #Nat.toText(id))));

      },
    );
    it.should(
      "Create and get draft by id",
      func() : async C.TestResult = async {
        var id = await Canister.getCurrentNodeId();
        id := id +1;
        let draft = await Canister.createDraftNode("CreateAndGetDraft");
        let result = await Canister.getDraftById(id);

        M.attempt(result.1, M.equals(T.text("CreateAndGetDraft")));

      },
    );
    it.should(
      "Get empty draft",
      func() : async C.TestResult = async {

        let result = await Canister.getDraftById(9999);

        M.attempt(result.1, M.equals(T.text("")));

      },
    );
    await it.runAll()
    // await it.run()
  };

};
