import { createActor, coffee_backend } from "../../declarations/coffee_backend";
import { AuthClient } from "@dfinity/auth-client"
import { HttpAgent } from "@dfinity/agent";
import * as React from 'react';
import { render } from 'react-dom';





class SupplyChain extends React.Component {

  constructor(props) {
    super(props);
    this.state = { actor: coffee_backend };

  }

  async getCaller() {
    document.getElementById("ii").value = this.state.actor.getCaller();
  }

  async addSupplier() {
    let userName = document.getElementById("newSupplierName");
    let userID = document.getElementById("newSupplierID");
    const supplier = {
      userName: userName.value,
      userId: userID.value,

    }
    this.state.actor.addSupplier(supplier);

    userName.value = "";
    userID.value = "";
    // actor.addSupplier(ii, userName);
  }

  async createNode() {
    //  let caller = await this.getCaller();
    // console.log("CALLER:"+caller);
    console.log("TEST");
    let title = document.getElementById("newNodeTitle");
    let children = document.getElementById("newNodeChildren");
    const tValue = title.value;
    const cValue = children.value;
    title.value = "";
    children.value = "";
    let result = "Created Node with ID: TEST";
    if (tValue.length > 0) {
      if (cValue.length == 0) {
        result += await this.state.actor.createRootNode(tValue, { userName: "test", userId: "test" });
      } else {
        let numbers = cValue.split(',').map(function (item) {
          return parseInt(item, 10);
        });
        result += await this.state.actor.createLeafNode(numbers, tValue, { userName: "test", userId: "test" });
      }
      document.getElementById("createResult").innerText = result;
    }
  }

  async login() {


    let authClient = await AuthClient.create();
    console.log('here');

    await new Promise((resolve) => {
      authClient.login({
        identityProvider: process.env.II_URL,
        onSuccess: resolve,
      });
    });

    // At this point we're authenticated, and we can get the identity from the auth client:
    const identity = authClient.getIdentity();
    console.log(identity);
    // Using the identity obtained from the auth client, we can create an agent to interact with the IC.
    const agent = new HttpAgent({ identity });
    // Using the interface description of our webapp, we create an actor that we use to call the service methods. We override the global actor, such that the other button handler will automatically use the new actor with the Internet Identity provided delegation.
    this.state.actor = createActor(process.env.COFFEE_BACKEND_CANISTER_ID, {
      agent,
    });
    const greeting = await this.state.actor.greet();
    document.getElementById("greeting").innerText = greeting;

    return false;

  }

  async getNodes() {
    let all = await this.state.actor.showAllNodes();
    console.log(all)
    console.log("TESTget")
    document.getElementById("allNodes").innerHTML = all;

    // all.map(n => console.log(n))
    //     return (
    //      <>
    //        <h1>All nodes</h1>
    //        <ul>
    //          {all.map((node) => <li>Title: {node.title}</li>)}
    //        </ul>
    //      </>
    //    );
  }

  render() {
    return (
      <div>
        <h1>Supply Chain</h1>
        <button type="submit" id="login" onClick={() => this.login()}>Login</button>
        <h2 id="greeting"></h2>
        <div>
          Add supplier
          <table>
            <tbody>
              <tr>
                {/* <tr><td>user id:</td><td id="ii"></td></tr> */}
                <td>user id:</td><td><input required id="newSupplierID"></input></td>
                <td>username :</td><td><input required id="newSupplierName"></input></td>
              </tr>
            </tbody>
          </table>
          <button onClick={() => this.addSupplier()}>Create Supplier</button>
          <br></br>
        </div>
        <div>
          Create node:
          <table>
            <tbody>
              <tr>
                <td>Title:</td><td><input required id="newNodeTitle"></input></td>
                <td>Child nodes:</td><td><input id="newNodeChildren" placeholder="1,2,..."></input></td>
              </tr>
            </tbody>
          </table>
          <button onClick={() => this.createNode()}>Create Node</button>
          <div id="createResult"></div>
        </div>
        <br></br>
        <button onClick={() => this.getNodes()}>Get all nodes</button>
        <div id="allNodes"></div>
      </div>
    );
  }
}

render(<SupplyChain />, document.getElementById('app'));
