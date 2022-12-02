import React from "react";
import { AuthClient } from "@dfinity/auth-client";
import { HttpAgent } from "@dfinity/agent";
import { canisterId as IICanisterID } from "../../../declarations/internet_identity_div";

/**
 * Header Component
 * @param {*} props 
 * @returns 
 */
export const Header = (props) => {

    const { 
        updateOrderList,
        updateUserTokens,
        setAgent,
        setUserPrincipal 
    } = props;

    /**
     * handleSuccess function
     * @param {*} authClient 
     */   
    const handleSuccess = async (authClient) => {
        // get identity
        const identity = await authClient.getIdentity();
        // get pricipal
        const principal = identity.getPrincipal();
        // get newAgent
        const newAgent = new HttpAgent({ identity });

        if (process.env.DFX_NETWORK === "local") {
            newAgent.fetchRootKey();
        }
        // get token info
        updateUserTokens(principal);
        updateOrderList();

        setUserPrincipal(principal);
        setAgent(newAgent);

        console.log(`User Principal: ${principal.toString()}`);
    };

    /**
     * handleLogin function
     */
    const handleLogin = async () => {
        // get internet identity URL
        let iiUrl;

        console.log("process.env.DFX_NETWORK", process.env.DFX_NETWORK);

        if (process.env.DFX_NETWORK === "local") {
            iiUrl = `http://localhost:8080/?canisterId=${IICanisterID}`;
        } else if (process.env.DFX_NETWORK === "ic") {
            iiUrl = "https://identity.ic0.app/#authorize";
        } else {
            // iiUrl = `https://${IICanisterID}.dfinity.network`;
            iiUrl = "https://identity.ic0.app/#authorize";
        }

        // ログイン認証を実行
        const authClient = await AuthClient.create();
        // login
        authClient.login({
            identityProvider: iiUrl,
            onSuccess: async () => {
                // call handleSuccess function
                handleSuccess(authClient);
            },
            onError: (error) => {
                console.error(`Login Failed: , ${error}`);
            },
        });
    };

    return (
        <ul>
            <li>ICP DEX</li>
            <li className="btn-login">
                <button onClick={handleLogin}>
                    Login Internet Identity
                </button>
            </li>
        </ul>
    );
};