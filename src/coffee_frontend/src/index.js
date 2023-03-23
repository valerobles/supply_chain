import { createActor,  coffee_backend } from "../../declarations/coffee_backend";
import { AuthClient } from "@dfinity/auth-client"
import { HttpAgent } from "@dfinity/agent";
let actor = coffee_backend;
document.querySelector("form").addEventListener("submit", async (e) => {
    e.preventDefault();
    const button = e.target.querySelector("button");

    const name = document.getElementById("name").value.toString();

    button.setAttribute("disabled", true);

    // Interact with foo actor, calling the greet method
    const greeting = await coffee_backend.greet(name);

    button.removeAttribute("disabled");

    document.getElementById("greeting").innerText = greeting;

    return false;
});
const loginButton = document.getElementById("login");
loginButton.onclick = async (e) => {
    e.preventDefault();

    let authClient = await AuthClient.create();

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
const greetButton = document.getElementById("greet");
greetButton.onclick = async (e) => {
    e.preventDefault();

    greetButton.setAttribute("disabled", true);

    // Interact with backend actor, calling the greet method
    const greeting = await actor.greet();

    greetButton.removeAttribute("disabled");

    document.getElementById("greeting").innerText = greeting;

    return false;
};