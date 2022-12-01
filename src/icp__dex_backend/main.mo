import Array "mo:base/Array";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";

import BalanceBook "balance_book";
import T "types";

// === Dex class
actor class Dex() = this {

  // ===  import balanceBook
  private var balance_book = BalanceBook.BalanceBook();

  // ===== DEPOSIT =====
  public shared (msg) func deposit(token : T.Token) : async T.DepositReceipt {
    // dip20 token
    let dip20 = actor (Principal.toText(token)) : T.DIPInterface;
    // feeを取得する
    let dip_fee = await fetch_dif_fee(token);
    // 残高を取得する
    let balance = await dip20.allowance(msg.caller, Principal.fromActor(this));

    // check
    if(balance <= dip_fee) {
      return #Err(#BalanceLow);
    };

    // transform
    let token_reciept = await dip20.transferFrom(msg.caller, Principal.fromActor(this), balance - dip_fee);

    switch token_reciept {
      case (#Err e) return #Err(#TransferFailure);
      case _ {};
    };

    // addToken
    balance_book.addToken(msg.caller, token, balance - dip_fee);
    return #Ok(balance - dip_fee);
  };

  // ===== WITHDRAW =====
  public shared (msg) func withdraw(token : T.Token, amount : Nat) : async T.WithdrawReceipt {
    if (balance_book.hasEnoughBalance(msg.caller, token, amount) == false) {
      return #Err(#BalanceLow);
    };

    // dip20 token
    let dip20 = actor (Principal.toText(token)) : T.DIPInterface;
    // transfer
    let txReceipt = await dip20.transfer(msg.caller, amount);

    switch txReceipt {
      case (#Err e) return #Err(#TransferFailure);
      case _ {};
    };
    // get fee
    let dip_fee = await fetch_dif_fee(token);

    // removeToken
    switch (balance_book.removeToken(msg.caller, token, amount + dip_fee)) {
      case null return #Err(#BalanceLow);
      case _ {};
    };

    return #Ok(amount);
  };

  // ==== fetch_dif_fee
  private func fetch_dif_fee(token : T.Token) : async Nat {
    // dip20 token
    let dip20 = actor (Principal.toText(token)) : T.DIPInterface;
    // get metadata
    let metadata = await dip20.getMetadata();

    return (metadata.fee);
  };

  // ===== DEX STATE FUNCTIONS =====
  public shared query func getBalance(user : Principal, token : T.Token) : async Nat {
    // check user data
    switch (balance_book.get(user)) {
      case null return 0;
      case (?token_balances) {
        switch (token_balances.get(token)) {
          case null return (0);
          case (?amount) {
            return (amount);
          };
        };
      };
    };
  };
};