import { createActor, supply_chain_backend } from "../../declarations/supply_chain_backend";
import { AuthClient } from "@dfinity/auth-client"
import { HttpAgent } from "@dfinity/agent";
import * as React from 'react';
import { render } from 'react-dom';





class SupplyChain extends React.Component {

  constructor(props) {
    super(props);
    this.state = {actor : supply_chain_backend};
   
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
    const caller = await this.state.actor.getCaller();
  
    let title = document.getElementById("newNodeTitle");
    let nextOwnerID = document.getElementById("newNodeNextOwner");
    let children = document.getElementById("newNodeChildren");
    const tValue = title.value;
    const cValue = children.value;
    const nValue = nextOwnerID.value;
    title.value = "";
    children.value = "";
    nextOwnerID.value="";
    let result = "";
    if (tValue.length > 0) {
      //Check if there are any child nodes. If not, the node is a "rootnode", which is a node without children
      let array = [];
      if (cValue.length == 0) {
        result += await this.state.actor.createLeafNode([0],tValue, caller,nValue);
      } else {
        //Split child node IDs by ","
        let numbers = cValue.split(',').map(function (item) {
          return parseInt(item, 10);
        });
        result += await this.state.actor.createLeafNode(numbers, tValue, caller,nValue);
      }
      if(result === "0"){
        if(caller==="2vxsx-fae"){
          result ="Node was not created. Login to a supplier account to create nodes."
        }
        result ="Node was not created. Account with id '"+caller+"' is not a supplier."
      }else{
        result = "Created Node with ID: "+ result;
      }
      document.getElementById("createResult").innerText = result;
    }
  }

  async login() {


    let authClient = await AuthClient.create();
  

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
    this.state.actor = createActor(process.env.SUPPLY_CHAIN_BACKEND_CANISTER_ID, {
      agent,
    });
    const greeting = await this.state.actor.greet();
    document.getElementById("greeting").innerText = greeting;

    return false;

  }

  async getNodes() {
    let all = await this.state.actor.showAllNodes();
    document.getElementById("allNodes").innerHTML = all;
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
                <td>Next Owner ID:</td><td><input required id="newNodeNextOwner"></input></td>
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
