import React from "react";

import {
    canisterId as DEXCanisterId,
    createActor,
} from "../../../declarations/icp__dex_backend";

/**
 * ListOrder component
 * @param {*} props 
 * @returns 
 */
export const ListOrder = (props) => {
    const { 
        agent, 
        userPrincipal, 
        orderList, 
        updateOrderList, 
        updateUserTokens 
    } = props;

    /**
     * createDEXActor function
     * @returns 
     */
    const createDEXActor = () => {
        // ログインしているユーザーを設定する
        const options = {
            agent: agent,
        };
        // return
        return createActor(DEXCanisterId, options);
    };

    /**
     * handleBuyOrder function
     * @param {*} order 
     * @returns 
     */
    const handleBuyOrder = async (order) => {
        try {
            // create DEX Actor
            const DEXActor = createDEXActor();
            // call placeOrder function
            const resultPlace = await DEXActor.placeOrder(
                order.to,
                Number(order.toAmount),
                order.from,
                Number(order.fromAmount)
            );

            if (!resultPlace.Ok) {
                alert(`Error: ${Object.keys(resultPlace.Err)[0]}`);
                return;
            }

            // update orderlist
            updateOrderList();
            // update token info
            updateUserTokens(userPrincipal);

            console.log("Trade Successful!");
        } catch (error) {
            console.log(`handleBuyOrder: ${error} `);
        }
    };

    /**
     * handleCancelOrder function
     * @param {*} id 
     * @returns 
     */
    const handleCancelOrder = async (id) => {
        try {
            // create DEX Actor
            const DEXActor = createDEXActor();
            //  call cancelOrder function
            const resultCancel = await DEXActor.cancelOrder(id);

            if (!resultCancel.Ok) {
                alert(`Error: ${Object.keys(resultCancel.Err)}`);
                return;
            }
            // update orderlist
            updateOrderList();

            console.log(`Canceled order ID: ${resultCancel.Ok}`);
        } catch (error) {
            console.log(`handleCancelOrder: ${error}`);
        }
    };

    return (
        <div className="list-order">
            <p>Order</p>
            <table>
                <tbody>
                    <tr>
                        <th>From</th>
                        <th>Amount</th>
                        <th></th>
                        <th>To</th>
                        <th>Amount</th>
                        <th>Action</th>
                    </tr>
                    {/* オーダー一覧を表示する */}
                    {orderList.map((order, index) => {
                        return (
                            <tr key={`${index}: ${order.token} `}>
                                <td data-th="From">{order.fromSymbol}</td>
                                <td data-th="Amount">{order.fromAmount.toString()}</td>
                                <td>→</td>
                                <td data-th="To">{order.toSymbol}</td>
                                <td data-th="Amount">{order.toAmount.toString()}</td>
                                <td data-th="Action">
                                    <div>
                                        {/* オーダーに対して操作（Buy, Cancel）を行うボタンを表示 */}
                                        <button
                                            className="btn-green"
                                            onClick={() => handleBuyOrder(order)}
                                        >
                                            Buy
                                        </button>
                                        <button
                                            className="btn-red"
                                            onClick={() => handleCancelOrder(order.id)}
                                        >
                                            Cancel
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        );
                    })}
                </tbody>
            </table>
        </div>
    );
};