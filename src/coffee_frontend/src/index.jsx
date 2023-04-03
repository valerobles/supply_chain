import { createActor, coffee_backend as actor } from "../../declarations/coffee_backend";
import { AuthClient } from "@dfinity/auth-client"
import { HttpAgent } from "@dfinity/agent";
import * as React from 'react';
import { render } from 'react-dom';





class SupplyChain extends React.Component {

  constructor(props) {
    super(props);
    this.state = {};
  }

  static ii = actor.getCaller();

  async getCaller() {
    document.getElementById("ii").value = ii;
  }

  async addSupplier() {
    let userName = document.getElementById("newSupplierName");
    let userID = document.getElementById("newSupplierID");
    const supplier = {
      userName: userName.value,
      userId: userID.value,

    }
    actor.addSupplier(supplier);

    userName.value = "";
    userID.value = "";
    // actor.addSupplier(ii, userName);
  }

  async createRootnode() {
    let title = document.getElementById("newRootNode").value
    actor.createRootNode(title);

    title = "";
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
      
      //FIXME set global actor to new Actor
      let newActor = createActor(process.env.COFFEE_BACKEND_CANISTER_ID, {
        agent,
      });

      const greeting = await newActor.greet();
      document.getElementById("greeting").innerText = greeting;
  
      return false;
   
  }

  async getNodes(){
    let all = await actor.showAllNodes();
    console.log(all)
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
          Create Root node:
          <table>
            <tbody>
              <tr>
                <td>Title:</td><td><input required id="newRootNode"></input></td>
              </tr>
            </tbody>
          </table>
          <button onClick={() => this.createRootnode()}>Create Root Node</button>
        </div>
        <br></br>
        <button onClick={() => this.getNodes()}>Get all nodes</button>
        <div id="allNodes"></div>
      </div>
    );
  }
}

render(<SupplyChain />, document.getElementById('app'));
