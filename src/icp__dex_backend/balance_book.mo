import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";

import T "types";

module {
    // === BalanceBook class
    public class BalanceBook() {

        // ユーザーとトークンの種類・量をマッピングする変数
        var balance_book = HashMap.HashMap<Principal, HashMap.HashMap<T.Token, Nat>>(10, Principal.equal, Principal.hash);

        // === get balance
        public func get(user : Principal) : ?HashMap.HashMap<T.Token, Nat> {
            return balance_book.get(user);
        };

        // === add token
        public func addToken(
            user : Principal, 
            token : T.Token, 
            amount : Nat
        ) {
            // check data is already existed
            switch (balance_book.get(user)) {
                case null {
                    var new_data = HashMap.HashMap<Principal, Nat>(2, Principal.equal, Principal.hash);
                    // put
                    new_data.put(token, amount);
                    balance_book.put(user, new_data);
                };
                case (?token_balance) {
                    // 指定したトークンが存在するかチェック
                    switch (token_balance.get(token)) {
                        case null {
                            token_balance.put(token, amount);
                        };
                        case (?balance) {
                            token_balance.put(token, balance + amount);
                        };
                    };
                };
            };
        };

        // === remove token function
        public func removeToken(
            user : Principal, 
            token : T.Token, 
            amount : Nat
        ) : ?Nat {
            // check
            switch (balance_book.get(user)) {
                case null return (null);
                case (?token_balance) {
                    switch (token_balance.get(token)) {
                        case null return (null);
                        case (?balance) {
                            // check
                            if (balance < amount) return (null);

                            if (balance == amount) {
                                // delete
                                token_balance.delete(token);
                            } else {
                                // update
                                token_balance.put(token, balance - amount);
                            };
                            return ?(balance - amount);
                        };
                    };
                };
            };
        };

        // === check enougth balance
        public func hasEnoughBalance(
            user : Principal, 
            token : T.Token, 
            amount : Nat
        ) : Bool {
            switch (balance_book.get(user)) {
                case null return (false);
                case (?token_balance) {
                    // check balance
                    switch (token_balance.get(token)) {
                        case null return (false);
                        case (?balance) {
                            return (balance >= amount);
                        };
                    };
                };
            };
        };
    };
};