import React, { useState } from "react";

import { Principal } from "@dfinity/principal";
import {
  canisterId as DEXCanisterId,
  createActor,
} from "../../../declarations/icp__dex_backend";

import { tokens } from "../utils/token";

/**
 * PlaceOrder
 * @param {*} props 
 * @returns 
 */
export const PlaceOrder = (props) => {
    const { 
        agent, 
        updateOrderList 
    } = props;

    // order data
    const [order, setOrder] = useState({
        from: "",
        fromAmount: 0,
        to: "",
        toAmount: 0,
    });

    /**
     * handleChangeOrder funtion
     * @param {} event 
     */
    const handleChangeOrder = (event) => {
        setOrder((prevState) => {
            return {
                ...prevState,
                [event.target.name]: event.target.value,
            };
        });
    };

    /**
     * handleSubmitOrder function
     * @param {*} event 
     * @returns 
     */
    const handleSubmitOrder = async (event) => {
        event.preventDefault();
        console.log(`order: ${order}`);

        try {
            // ログインしているユーザーがDEXとやりとりを行うためにアクターを作成する
            const options = {
                agent: agent,
            };
            const DEXActor = createActor(DEXCanisterId, options);

            // get token data
            const fromToken = tokens.find((e) => e.tokenSymbol === order.from);
            const fromPrincipal = fromToken.canisterId;
            // get token data
            const toToken = tokens.find((e) => e.tokenSymbol === order.to);
            const toPrincipal = toToken.canisterId;

            // call placeOrder function
            const resultPlace = await DEXActor.placeOrder(
                Principal.fromText(fromPrincipal),
                Number(order.fromAmount),
                Principal.fromText(toPrincipal),
                Number(order.toAmount)
            );

            if (!resultPlace.Ok) {
                alert(`Error: ${Object.keys(resultPlace.Err)[0]}`);
                return;
            }
            console.log(`Created order:  ${resultPlace.Ok[0].id}`);

            // 更新する。
            updateOrderList();
        } catch (error) {
            console.log(`handleSubmitOrder: ${error} `);
        }
    };

    return (
        <>
            <div className="place-order">
                <p>PLACE ORDER</p>
                {/* オーダーを入力するフォームを表示 */}
                <form className="form" onSubmit={handleSubmitOrder}>
                    <div>
                        <div>
                            <label>From</label>
                            <select
                                name="from"
                                type="from"
                                onChange={handleChangeOrder}
                                required
                            >
                                <option value="">Select token</option>
                                <option value="TGLD">TGLD</option>
                                <option value="TSLV">TSLV</option>
                            </select>
                        </div>
                        <div>
                            <label>Amount</label>
                            <input
                                name="fromAmount"
                                type="number"
                                onChange={handleChangeOrder}
                                required
                            />
                        </div>
                        <div>
                            <span>→</span>
                        </div>
                        <div>
                            <label>To</label>
                            <select 
                                name="to" 
                                type="to" 
                                onChange={handleChangeOrder} 
                                required
                            >
                                <option value="">Select token</option>
                                <option value="TGLD">TGLD</option>
                                <option value="TSLV">TSLV</option>
                            </select>
                        </div>
                        <div>
                            <label>Amount</label>
                            <input
                                name="toAmount"
                                type="number"
                                onChange={handleChangeOrder}
                                required
                            />
                        </div>
                    </div>
                    <button className="btn-green" type="submit">
                        Submit Order
                    </button>
                </form>
            </div>
        </>
    );
};