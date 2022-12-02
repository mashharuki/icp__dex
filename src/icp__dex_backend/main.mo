import Array "mo:base/Array";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";

import BalanceBook "balance_book";
import Exchange "exchange";
import T "types";

// === Dex class
actor class Dex() = this {

  // ===  import balanceBook
  private var balance_book = BalanceBook.BalanceBook();
  private var last_id : Nat32 = 0;
  // オーダーを管理するモジュール
  private var exchange = Exchange.Exchange(balance_book);
  
  // stable 変数 
  private stable var ordersEntries : [T.Order] = [];
  private stable var balanceBookEntries : [var (Principal, [(T.Token, Nat)])] = [var];


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

    for (order in exchange.getOrders().vals()) {
      if (msg.caller == order.owner and token == order.from) {
        //ユーザーの残高とオーダーのfromAmaountを比較する
        if (balance_book.hasEnoughBalance(msg.caller, token, order.fromAmount) == false) {
          // call cancelOrder function
          switch (exchange.cancelOrder(order.id)) {
            case null return (#Err(#DeleteOrderFailure));
            case (?cancel_order) return (#Ok(amount));
          };
        };
      };
    };

    return #Ok(amount);
  };

  // ===== create Order =====
  public shared (msg) func placeOrder(
    from: T.Token,
    fromAmount: Nat,
    to: T.Token,
    toAmount: Nat,
  ): async T.PlaceOrderReceipt{
    // check
    for (order in exchange.getOrders().vals()) {
      if (msg.caller == order.owner and from == order.from) {
        return (#Err(#OrderBookFull));
      };
    };

    // check balance
    if (balance_book.hasEnoughBalance(msg.caller, from, fromAmount) == false) {
      return (#Err(#InvalidOrder));
    };

    // get orderID
    let id : Nat32 = nextId();

    let owner = msg.caller;

    // order
    let order : T.Order = {
      id;
      owner;
      from;
      fromAmount;
      to;
      toAmount;
    };

    // call addOrder
    exchange.addOrder(order);
    return (#Ok(exchange.getOrder(id)));
  };

  // === cancelOrder
  public shared (msg) func cancelOrder(order_id : T.OrderId) : async T.CancelOrderReceipt {
    // check exist order
    switch (exchange.getOrder(order_id)) {
      case null return (#Err(#NotExistingOrder));
      case (?order) {
        if (msg.caller != order.owner) {
          return (#Err(#NotAllowed));
        };
        // call cancel order
        switch (exchange.cancelOrder(order_id)) {
          case null return (#Err(#NotExistingOrder));
          case (?cancel_order) {
            return (#Ok(cancel_order.id));
          };
        };
      };
    };
  };

  // === getOrders function
  public query func getOrders() : async ([T.Order]) {
    return (exchange.getOrders());
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

  // === get Order ID
  private func nextId() : Nat32 {
    last_id += 1;
    return (last_id);
  };

  // ===== UPGRADE =====
  system func preupgrade() {
    // DEXに預けられたトークンデータを`Array`に保存
    balanceBookEntries := Array.init(balance_book.size(), (Principal.fromText("aaaaa-aa"), []));

    var i = 0;

    for ((x, y) in balance_book.entries()) {
      balanceBookEntries[i] := (x, Iter.toArray(y.entries()));
      i += 1;
    };
    // book内で管理しているオーダーを保管
    ordersEntries := exchange.getOrders();
  };

  // キャニスターのアップグレード後、`Array`から`HashMap`に再構築する。
  system func postupgrade() {
    // balance_bookを再構築
    for ((key : Principal, value : [(T.Token, Nat)]) in balanceBookEntries.vals()) {
      let tmp : HashMap.HashMap<T.Token, Nat> = HashMap.fromIter<T.Token, Nat>(Iter.fromArray<(T.Token, Nat)>(value), 10, Principal.equal, Principal.hash);
      balance_book.put(key, tmp);
    };

    // orderを再構築
    for (order in ordersEntries.vals()) {
      // call addOrder function
      exchange.addOrder(order);
    };

    // メモリをクリアする
    balanceBookEntries := [var];
    ordersEntries := [];
  };
};