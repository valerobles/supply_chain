import SharedMemory "mo:base/ExperimentalStableMemory";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Cycles "mo:base/ExperimentalCycles";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";




actor Main {
      
    private stable var storageWasm : [Nat8] = [];

    type CanisterSettings = {
    controllers : ?[Principal];
    compute_allocation : ?Nat;
    memory_allocation : ?Nat;
    freezing_threshold :?Nat;
    };

    type canister_id = Principal;

    let IC =
        actor "aaaaa-aa" : actor {

        create_canister : {
            settings : (s : CanisterSettings)
            } -> async { canister_id : Principal };

        canister_status : { canister_id : Principal } ->
            async { // richer in ic.did
            cycles : Nat
            };

            install_code : ({
                mode : { #install; #reinstall; #upgrade };
                canister_id : canister_id;
                wasm_module : Blob;
                arg : Blob;
                }) -> async ();

        stop_canister : { canister_id : Principal } -> async ();

        delete_canister : { canister_id : Principal } -> async ();
        };


        public shared ({caller}) func storageLoadWasm(blob : [Nat8]) : async ({total : Nat; chunks : Nat}) {
        

            // Issue: https://forum.dfinity.org/t/array-to-buffer-in-motoko/15880/15
             let buffer: Buffer.Buffer<Nat8> = Buffer.fromArray<Nat8>(storageWasm);
             let chunks: Buffer.Buffer<Nat8> = Buffer.fromArray<Nat8>(blob);
             buffer.append(chunks);
             storageWasm := Buffer.toArray(buffer);

           // storageWasm := Array.append<Nat8>(storageWasm, blob);

            // return total wasm sizes
            return {
            total = storageWasm.size();
            chunks = blob.size();
            };
        };



    public func create() : async () {



        let settings_ : CanisterSettings = {
                controllers = ?[Principal.fromActor(Main)];
                compute_allocation = null;
                memory_allocation = null;
                freezing_threshold = null;
            };

        //Debug.print("balance before: " # Nat.toText(Cycles.balance()));
        Cycles.add(Cycles.balance()/2);
        let cid = await IC.create_canister({settings = settings_});
        Debug.print("canister id " # Principal.toText(cid.canister_id) );
        let status = await IC.canister_status(cid);
        Debug.print("canister " #Principal.toText(cid.canister_id) #" has " # Nat.toText(status.cycles) # " cycles");

        await IC.install_code({
            mode = #install;
            canister_id = cid.canister_id;
            wasm_module = Blob.fromArray(storageWasm);
            arg = Blob.fromArray([]);
            });
        //await IC.stop_canister(cid);
        //await IC.delete_canister(cid);
        //Debug.print("balance after: " # Nat.toText(Cycles.balance()));
    };

    };

            // let IC0 : Management = actor ("aaaaa-aa");
            // let this = Principal.fromActor(self);
            // var cycle_to_add = coupon.cycle;
            // let canister_id = switch (Queue.popFront(canisters_reserve)) {
            //   case (?canister_id) { canister_id };
            //   case null {
            //     Cycles.add(cycle_to_add);
            //     cycle_to_add := 0;
            //     (await IC0.create_canister({ settings = ?{ controllers = ?[this] } })).canister_id;
            //   };
            // };
            // await IC0.install_code({
            //   mode = #install;
            //   canister_id = canister_id;
            //   wasm_module = binary;
            //   arg = Blob.fromArray([]);
            // });


        // private var memoryThreshold : Nat = 1000;  // Memory threshold in bytes
        // private var memory : Nat = 0;
        
        // public func trackMemoryUsage(): async () {
        //     let currentMemorySize = memory;
        //     memory := memory + 900;
        //     Debug.print(Nat.toText(currentMemorySize));
            
        //     if (currentMemorySize >= memoryThreshold) {
        //         let newCanisterId = await createNewCanister();  
        
        //         Debug.print(Principal.toText(newCanisterId));

        //     };
        // };
        

        // private func createNewCanister() : async Types.canister_id {
        //     let governanceCanister : actor {
        //         provisional_create_canister_with_cycles : ( r: Types.CanisterSettings,amount: Nat) -> async Types.canister_id;
        //     } = actor "aaaaa-aa";  // governance canister ID

        //     let createCanisterRequest : Types.CanisterSettings = {
        //         controllers = Principal.fromActor(Main);
        //         compute_allocation = 0;
        //         memory_allocation = 0;
        //         freezing_threshold = 0;
        
        //     };

        //     let canisterId = await governanceCanister.provisional_create_canister_with_cycles(
        //         createCanisterRequest, 100000000000
        //     );
        //     return canisterId;
        // };


        //    public func createNewCanister() : async Text {
        //     let governanceCanister : actor {
        //     create_canister : () -> async Text;
        //     } = actor "aaaaa-aa";  //  governance canister ID

        //     let canisterId = await governanceCanister.create_canister();
        //     return canisterId;
        // };
