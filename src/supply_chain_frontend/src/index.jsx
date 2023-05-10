import { createActor, supply_chain_backend } from "../../declarations/supply_chain_backend";
import { AuthClient } from "@dfinity/auth-client"
import { HttpAgent } from "@dfinity/agent";
import * as React from 'react';
import { render } from 'react-dom';
import React, { useState } from 'react';






class SupplyChain extends React.Component {

  constructor(props) {
    super(props);
    this.state = { actor: supply_chain_backend, file: null, formFields: [{ label: '', text: '' }] };
  }

  handleAddField = () => {
    const { formFields } = this.state;
    this.setState({ formFields: [...formFields, { label: '', text: '' }] });
  };

  handleRemoveField = (index) => {
    const { formFields } = this.state;
    const newFormFields = [...formFields];
    newFormFields.splice(index, 1);
    this.setState({ formFields: newFormFields });
  };

  handleFieldChange = (index, fieldName, event) => {
    const { formFields } = this.state;
    const newFormFields = [...formFields];
    newFormFields[index][fieldName] = event.target.value;
    this.setState({ formFields: newFormFields });

  };

  printForm = () => {
    console.log(this.state.formFields)
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
    let response = await this.state.actor.addSupplier(supplier);

    userName.value = "";
    userID.value = "";
    document.getElementById("supplierResponse").innerText = response;
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
    nextOwnerID.value = "";
    let response = "";
    if (tValue.length > 0) {
      //Check if there are any child nodes. If not, the node is a "rootnode", which is a node without children
      let array = [];
      if (cValue.length == 0) {
        //response += await this.state.actor.createDraftNode([0], tValue, caller, nValue);

        response += await this.state.actor.createLeafNode([0], tValue, caller, nValue);
      } else {
        //Split child node IDs by ","
        let numbers = cValue.split(',').map(function (item) {
          return parseInt(item, 10);
        });
        response += await this.state.actor.createLeafNode(numbers, tValue, caller, nValue);
      }

      if (caller === "2vxsx-fae") {
        response = "Node was not created. Login to a supplier account to create nodes."
      }

      document.getElementById("createResult").innerText = response;
    }
  }

  async createDraftNode() {
    const caller = await this.state.actor.getCaller();
    let response = "";
    if (caller === "2vxsx-fae") {
      response = "Node was not created. Login to a supplier account to create nodes."
    } else {

      let title = document.getElementById("newNodeTitle");

      const tValue = title.value;

      title.value = "";

      let response = "";
      if (tValue.length > 0) {
        //Check if there are any child nodes. If not, the node is a "rootnode", which is a node without children

        response += await this.state.actor.createDraftNode(tValue);
      }
    }

    document.getElementById("createResult").innerText = response;
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

  async getDraftBySupplier() {
    let result = await this.state.actor.getDraftsBySupplier()
    console.log(result)
  }



  async getNodes() {
    let all = await this.state.actor.showAllNodes();
    document.getElementById("allNodes").innerHTML = all;
  }
  async getSuppliers() {
    let all = await this.state.actor.getSuppliers();
    document.getElementById("suppliers").innerHTML = all;
  }
  async getChildNodes() {
    let tree = document.getElementById("parentId");
    const tValue = parseInt(tree.value, 10);
    if (tValue >= 0) {
      let nodes = await this.state.actor.showAllChildNodes(tValue);
      nodes = nodes.replace(/\n/g, '<br>');
      console.log("Nodes:" + nodes)
      if (nodes === "") { nodes = "No child nodes found" }
      document.getElementById("treeResult").innerHTML = nodes;
    } else {
      document.getElementById("treeResult").innerHTML = "Error: Invalid ID"
    }
  }
  // test() {
  //    input = document.querySelector('input');
  //    input?.addEventListener('change', ($event) => {
  //     file = $event.target.files?.[0];})

  //  }




  // Upload and download code was taken by dfinity's example project and was adapted to this project
  // https://github.com/carstenjacobsen/examples/tree/master/motoko/fileupload
  async handleFileSelection(event) {
    this.state.file = event.target.files[0];
    console.log(this.state.file)

  }

  async upload() {

    if (!this.state.file) {
      alert('No file selected');
      return;
    }

    let newName = this.state.file.name.replace(/\s/g, ""); // remove whitespaces so no error occurs in the GET method URL
    this.state.file = new File([this.state.file], newName, { type: this.state.file.type });
    console.log(this.state.file);



    console.log('start upload');

    const batch_name = this.state.file.name;
    const promises = [];
    const chunkSize = 1500000; //Messages to canisters cannot be larger than 2MB. The chunks are of size 1.5MB

    for (let start = 0; start < this.state.file.size; start += chunkSize) {

      // Create a chunk from file in size defined in chunkSize
      const chunk = this.state.file.slice(start, start + chunkSize); // returns a Blob obj
      console.log(chunk);

      // Fill array with the uploadChunkt function. The array be executed later
      // "uploadChunk" takees the batch_name(file name) and the chunk
      promises.push(this.uploadChunk({
        batch_name,
        chunk
      }));
    }

    // Executes the "uploadChunk" defined in the promises array. Returns the chunkIDs created in the backend
    const chunkIds = await Promise.all(promises);

    console.log(chunkIds);

    //Finish upload by commiting file batch to be saved in backend canister
    await this.state.actor.commit_batch({
      batch_name,
      chunk_ids: chunkIds.map(({ chunk_id }) => chunk_id),
      content_type: this.state.file.type
    })

    console.log('uploaded');

    // Once the files has been saved in the backend canister it can be loaded to be seen on the frontend
    this.loadImage(batch_name);
  }

  // Takes a record of batch_name and chunk
  // calls the backend canister method "create_chunk"
  //converts chunk of type Blob into a Uint8Array to send it to backend canister. Motoko reads it as [Nat8]
  async uploadChunk({ batch_name, chunk }) {
    return this.state.actor.create_chunk({
      batch_name,
      content: [...new Uint8Array(await chunk.arrayBuffer())]
    });
  }



  loadImage(batch_name) {
    if (!batch_name) {
      return;
    }


    const newImage = document.createElement('img');
    // do a GET request to the backend canister to recieve image
    newImage.src = `http://localhost:4943/assets/${batch_name}?canisterId=ryjl3-tyaaa-aaaaa-aaaba-cai`; //backend canister ID

    const img = document.querySelector('section:last-of-type img');
    img?.parentElement.removeChild(img);

    const section = document.querySelector('section:last-of-type');
    section?.appendChild(newImage);
  }





  render() {
    const { formFields } = this.state;
    return (
      <div>
        <h1>Supply Chain</h1>
        <button type="submit" id="login" onClick={() => this.login()}>Login</button>
        <h2 id="greeting"></h2>
        <div>
          <h3> Add supplier</h3>
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
          <div id="supplierResponse"></div>
          <br></br>
        </div>
        <div>
          <h3>Create Draft node:</h3>
          <table>
            <tbody>
              <tr>
                <td>Title:</td><td><input required id="newNodeTitle"></input></td>
              </tr>
            </tbody>
          </table>
          <button onClick={() => this.createDraftNode()}>Create Draft Node</button>
          <div id="createResult"></div>
        </div>
        <br></br>
        <button onClick={() => this.getNodes()}>Get all nodes</button>
        <div id="allNodes"></div>
        <button onClick={() => this.getSuppliers()}>Get all suppliers</button>
        <div id="suppliers"></div>
        <br></br>
        <div>
          <h3> Get Chain by last node ID</h3>
          <table>
            <tbody>
              <tr>
                <td>Last node ID:</td><td><input type="number" required id="parentId"></input></td>
              </tr>
            </tbody>
          </table>
          <button onClick={() => this.getChildNodes()}>Show Child Nodes</button>
          <div id="treeResult"></div>
        </div>
        <h3>Upload file</h3>
        <section>
          <label for="image">Image:</label>
          <input id="image" alt="image" onChange={(e) => this.handleFileSelection(e)} type="file" accept="image/x-png,image/jpeg,image/gif,image/svg+xml,image/webp" />
          <button className="upload" onClick={() => this.upload()}>Upload</button>
          <section></section>
        </section>
        <h1>Complete Draft</h1>
        <table>
        <tbody>
            <tr>
              <td>Next Owner ID:</td><td><input required id="newNodeNextOwner"></input></td>
              <td>Child nodes:</td><td><input id="newNodeChildren" placeholder="1,2,..."></input></td>
            </tr>
          </tbody>
          </table>
        <div>
    
        
          {formFields.map((field, index) => (
            <div key={index}>
              <input
                type="text"
                value={field.label}
                onChange={(event) => this.handleFieldChange(index, 'label', event)}
              />
              <input
                type="text"
                value={field.text}
                onChange={(event) => this.handleFieldChange(index, 'text', event)}
              />
              {index > 0 && (
                <button type="button" onClick={() => this.handleRemoveField(index)}>
                  Remove Field
                </button>
              )}
            </div>
          ))}
          <button type="button" onClick={()=>this.handleAddField()}>
            Add Field
          </button>
          <button type="button" onClick={()=>this.printForm()}>
            Save
          </button>
          <button type="button" onClick={()=>this.printForm()}>
            Finalize
          </button>
          <button type="button" onClick={()=>this.getDraftBySupplier()}>
            Get drafts by supplier
          </button>
        </div>
      </div>
    );
  }
}

render(<SupplyChain />, document.getElementById('create_node'));
