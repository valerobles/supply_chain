import { createActor,  coffee_backend as actor } from "../../declarations/coffee_backend";
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

  async getCaller(){
    document.getElementById("ii").value = ii; 
  }

  async addSupplier(){
    let userName = document.getElementById("newSupplierName");
    let userID = document.getElementById("newSupplierID");
    const supplier = {
        userName:   userName.value,
        userId: userID.value,
        
    }
    actor.addSupplier(supplier);

    userName.value = "";
    userID.value = "";
    // actor.addSupplier(ii, userName);
  }

  async createRootnode(){
      let title = document.getElementById("newRootNode").value
      actor.createRootNode(title);

      title = "";
  }

  async login(){
    let loginButton = document.getElementById("login");
    loginButton.onclick = async (e) => {
        e.preventDefault();
    
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
        // Using the identity obtained from the auth client, we can create an agent to interact with the IC.
        const agent = new HttpAgent({ identity });
        // Using the interface description of our webapp, we create an actor that we use to call the service methods. We override the global actor, such that the other button handler will automatically use the new actor with the Internet Identity provided delegation.
        actor = createActor(process.env.COFFEE_BACKEND_CANISTER_ID, {
            agent,
        });
    
        return false;
    };
  }

  render() {
    return (
      <div>
        <h1>Supply Chain</h1>
        <button type="submit" id="login">Login</button>
        <div>
            Add supplier
            <table>
                {/* <tr><td>user id:</td><td id="ii"></td></tr> */}
                <tr><td>user id:</td><td><input required id="newSupplierID"></input></td></tr>
                <tr><td>username :</td><td><input required id="newSupplierName"></input></td></tr>
            </table>
            <button onClick={() => this.addSupplier()}>Create Supplier</button>
            <br></br>
        </div>
        <div>
          Create Root node:
          <table>
            <tr><td>Title:</td><td><input required id="newRootNode"></input></td></tr>
          </table>
          <button onClick={() => this.createRootnode()}>Create Root Node</button>
        </div>
    
      </div>
    );
  }
}

render(<SupplyChain/>, document.getElementById('app'));
