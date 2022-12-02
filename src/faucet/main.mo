import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";

import T "types";

// === Faucet ===
shared (msg) actor class Faucet() = this {

    private type Token = Principal;
    private let FAUCET_AMOUNT : Nat = 1_000;

    private stable var faucetBookEntries : [var (Principal, [Token])] = [var];

    // ユーザーとトークンをマッピング
    private var faucet_book = HashMap.HashMap<Principal, [Token]>(
        10,
        Principal.equal,
        Principal.hash,
    );

    // === getToken
    public shared (msg) func getToken(token: Token): async T.FaucetReceipt {
        // get receipt
        let faucet_receipt = await checkDistribution(msg.caller, token);

        switch (faucet_receipt) {
            case(#Err e) return #Err(e);
            case _ {};
        };

        // `Token` PrincipalでDIP20アクターのインスタンスを生成
        let dip20 = actor (Principal.toText(token)) : T.DIPInterface;
        // トークンを転送する
        let txReceipt = await dip20.transfer(msg.caller, FAUCET_AMOUNT);

        switch txReceipt {
            case (#Err e) return #Err(#FaucetFailure);
            case _ {};
        };

        addUser(msg.caller, token);
        return #Ok(FAUCET_AMOUNT);
    };

    // === addUser
    private func addUser(user : Principal, token : Token) {
        switch (faucet_book.get(user)) {
            case null {
                let new_data = Array.make<Token>(token);
                // put
                faucet_book.put(user, new_data);
            };

            case (?tokens) {
                let buff = Buffer.Buffer<Token>(2);

                for (token in tokens.vals()) {
                    buff.add(token);
                };

                // put
                faucet_book.put(user, Buffer.toArray<Token>(buff));
            };
        };
    };

    // ===  checkDistribution
    private func checkDistribution(user : Principal, token : Token) : async T.FaucetReceipt {
        // `Token` PrincipalでDIP20アクターのインスタンスを生成
        let dip20 = actor (Principal.toText(token)) : T.DIPInterface;
        // get balance
        let balance = await dip20.balanceOf(Principal.fromActor(this));

        if(balance == 0) {
            return (#Err(#InsufficientToken));
        };

        switch (faucet_book.get(user)) {
            case null return #Ok(FAUCET_AMOUNT);

            case (?tokens) { 
                switch (Array.find<Token>(tokens, func(x : Token) { x == token })) {
                    case null return #Ok(FAUCET_AMOUNT);
                    case (?token) return #Err(#AlreadyGiven);
                };
            };
        };
    };

    // === preupgrade function
    system func preupgrade() {
        // init
        faucetBookEntries := Array.init(faucet_book.size(), (Principal.fromText("aaaaa-aa"), []));
        var i = 0;

        for ((x, y) in faucet_book.entries()) {
            faucetBookEntries[i] := (x, y);
            i += 1;
        };
    };

    // === postupgrade function
    system func postupgrade() {
        // 再構築
        for ((key : Principal, value : [Token]) in faucetBookEntries.vals()) {
            faucet_book.put(key, value);
        };
        // memory clear
        faucetBookEntries := [var];
    };
}