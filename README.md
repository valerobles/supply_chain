# Supply Chain
The Internet Computer (IC) is a decentralized network built using blockchain technology, launched in 2021 by the DFINITY Foundation1. Its primary purpose is to provide a platform capable of hosting fully decentralized applications (DApps) and services while also competing with the low cost and high speed of centralized cloud hosting. To analyse the strengths and weaknesses of the IC, this DApp of a Supply-Chain management tool was created.

## Developers

- Valeria
- Luca

## Key UI features

- User management
- Start a new Supply-Chain
- Contribute to an existing Supply-Chain
- Add who can continue the Supply-Chain after them 
- Add labels and texts to nodes of the Supply-Chain for information regarding the process, E.g. date of delivery, quantity, etc. 
- Upload and download files and images (quality file report, confirmation letters, etc.) 
- View Supply-Chains

## Technologies used
- Javascript, ReactJS, CSS
- Motoko
- Node.js
- DFX version 0.14.1

## Hardware requirements
DFX natively only supports Unix based systems: This project was developed and tested on macOS, both with the intel i7 processor and the M1 Chip.
Should also work on Linux.
## Running the project locally

If you want to run the project locally, you can use the following commands:

```bash
# Starts the replica, running in the background
dfx start --background

# Download all of the dependencies
npm install

# Deploys your canisters to the replica and generates your candid interface
dfx deploy

# Update canister settings for canister creation
dfx canister update-settings --add-controller be2us-64aaa-aaaaa-qaabq-cai assets_db

# Deploy canister again with new settings
dfx deploy
```

Once the job completes, your application will be available at `http://localhost:4943?canisterId={asset_canister_id}`.
Additionally, if you are making frontend changes, you can start a development server with

```bash
npm start
```
Which will start a server at `http://localhost:8080`, proxying API requests to the replica at port 4943.

You can stop the environment by running
```bash
dfx stop
```
## After Deployment
To allow canister creation you must upload the wasm module for the canister asset_db. 
You do this over the UI after logging in. At the top left you will find a button for uploading the wasm file. Select it and then press "Install Wasm" 

## Common Error
If this error appears 

```bash
ERROR in ./src/supply_chain_frontend/src/index.jsx 30:20-59
Module not found: Error: Can't resolve '../../declarations/assets_db' in
```
Use the following command and redeploy
```bash
# Generates canister dependencies for frontend
dfx generate
```
