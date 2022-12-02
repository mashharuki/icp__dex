import React from "react";

import { Principal } from "@dfinity/principal";
import {
    canisterId as DEXCanisterId,
    createActor as DEXCreateActor,
    icp__dex_backend as DEX,
} from "../../../declarations/icp__dex_backend";
import {
    canisterId as faucetCanisterId,
    createActor as faucetCreateActor,
} from "../../../declarations/faucet";
import { LoadingIndicator } from "./LoadingIndicator"; 
import { tokens } from "../utils/token";

/**
 * UserBoard Component
 * @param {*} props 
 * @returns 
 */
export const UserBoard = (props) => {
    const { 
        agent, 
        isLoading,
        setIsLoading,
        userPrincipal, 
        userTokens, 
        setUserTokens 
    } = props;

    const TOKEN_AMOUNT = 500;

    const options = {
        agent: agent,
    };

    /**
     * updateUserToken function
     * @param {*} updateIndex 
     */
    const updateUserToken = async (updateIndex) => {
        // get token balance
        const balance = await tokens[updateIndex].canister.balanceOf(userPrincipal);
        // ユーザーがDEXに預けたトークン量を取得
        const dexBalance = await DEX.getBalance(
            userPrincipal,
            Principal.fromText(tokens[updateIndex].canisterId)
        );
        
        // set user tokens
        setUserTokens(
            userTokens.map((userToken, index) =>
                index === updateIndex ? {
                    symbol: userToken.symbol,
                    balance: balance.toString(),
                    dexBalance: dexBalance.toString(),
                    fee: userToken.fee,
                } : userToken
            )
        );
    };

    /**:
     * handleDeposit function
     */
    const handleDeposit = async (updateIndex) => {

        try {
            setIsLoading(true);
            // create actor
            const DEXActor = DEXCreateActor(DEXCanisterId, options);
            const tokenActor = tokens[updateIndex].createActor(
                tokens[updateIndex].canisterId,
                options
            );

            // ユーザーの代わりにDEXがトークンを転送することを承認する
            const resultApprove = await tokenActor.approve(
                Principal.fromText(DEXCanisterId),
                TOKEN_AMOUNT
            );

            if (!resultApprove.Ok) {
                alert(`Error: ${Object.keys(resultApprove.Err)[0]}`);
                return;
            }

            // deposit
            const resultDeposit = await DEXActor.deposit(
                Principal.fromText(tokens[updateIndex].canisterId)
            );

            if (!resultDeposit.Ok) {
                alert(`Error: ${Object.keys(resultDeposit.Err)[0]}`);
                return;
            }

            console.log(`resultDeposit: ${resultDeposit.Ok}`);
            // updateUserToken
            updateUserToken(updateIndex);
            setIsLoading(false);
        } catch (error) {
            console.log(`handleDeposit: ${error} `);
            setIsLoading(false);
        }
    };

    /**
     * handleWithdraw function
     * @param { } updateIndex 
     * @returns 
     */
    const handleWithdraw = async (updateIndex) => {

        try {
            setIsLoading(true);
            const DEXActor = DEXCreateActor(DEXCanisterId, options);
            // withdraw
            const resultWithdraw = await DEXActor.withdraw(
                Principal.fromText(tokens[updateIndex].canisterId),
                TOKEN_AMOUNT
            );

            if (!resultWithdraw.Ok) {
                alert(`Error: ${Object.keys(resultWithdraw.Err)[0]}`);
                return;
            }
            console.log(`resultWithdraw: ${resultWithdraw.Ok}`);

            // updateUserToken
            updateUserToken(updateIndex);
            setIsLoading(false);
        } catch (error) {
            console.log(`handleWithdraw: ${error} `);
            setIsLoading(false);
        }
    };

    // Faucetからトークンを取得する
    const handleFaucet = async (updateIndex) => {

        try {
            setIsLoading(true);
            // create actor
            const faucetActor = faucetCreateActor(faucetCanisterId, options);
            // call getToken function
            const resultFaucet = await faucetActor.getToken(
                Principal.fromText(tokens[updateIndex].canisterId)
            );

            if (!resultFaucet.Ok) {
                alert(`Error: ${Object.keys(resultFaucet.Err)[0]}`);
                return;
            }
            console.log(`resultFaucet: ${resultFaucet.Ok}`);

            // updateUserToken
            updateUserToken(updateIndex);
            setIsLoading(false);
        } catch (error) {
            console.log(`handleFaucet: ${error}`);
            setIsLoading(false);
        }
    };

    return (
        <>
            <div className="user-board">
                {isLoading ? (
                    <LoadingIndicator/>
                ) : ( 
                    <>
                        <h2>User</h2>
                        <li>principal ID: {userPrincipal.toString()}</li>
                        <table>
                            <tbody>
                                <tr>
                                    <th>Token</th>
                                    <th>Balance</th>
                                    <th>DEX Balance</th>
                                    <th>Fee</th>
                                    <th>Action</th>
                                </tr>
                                {/* トークンのデータを一覧表示する */}
                                {userTokens.map((token, index) => {
                                    return (
                                        <tr key={`${index} : ${token.symbol} `}>
                                            <td data-th="Token">{token.symbol}</td>
                                            <td data-th="Balance">{token.balance}</td>
                                            <td data-th="DEX Balance">{token.dexBalance}</td>
                                            <td data-th="Fee">{token.fee}</td>
                                            <td data-th="Action">
                                                <div>
                                                    <button
                                                        className="btn-green"
                                                        onClick={() => handleDeposit(index)}
                                                    >
                                                        Deposit
                                                    </button>
                                                    <button
                                                        className="btn-red"
                                                        onClick={() => handleWithdraw(index)}
                                                    >
                                                        Withdraw
                                                    </button>
                                                    <button
                                                        className="btn-blue"
                                                        onClick={() => handleFaucet(index)}
                                                    >
                                                        Faucet
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    );
                                })}
                            </tbody>
                        </table>
                    </>
                )}
            </div>
        </>
    );
};