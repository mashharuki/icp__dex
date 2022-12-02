import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";

import BalanceBook "balance_book";
import T "types";

module {
    // === Exchange class
    public class Exchange(balance_book : BalanceBook.BalanceBook) {

        // order map
        var orders = HashMap.HashMap<T.OrderId, T.Order>(
            0,
            func(order_id_x, order_id_y) { return (order_id_x == order_id_y) },
            func(order_id_x) { return (order_id_x) },
        );

        // get orders
        public func getOrders() : [T.Order] {
            let buff = Buffer.Buffer<T.Order>(10);
            // add
            for (order in orders.vals()) {
                buff.add(order);
            };
            // convert to Array
            return (Buffer.toArray<T.Order>(buff));
        };

        // get order
        public func getOrder(id : Nat32) : ?T.Order {
            return (orders.get(id));
        };

        // delete order
        public func cancelOrder(id : T.OrderId) : ?T.Order {
            return (orders.remove(id));
        };

        // add order
        public func addOrder(new_order : T.Order) {
            // put
            orders.put(new_order.id, new_order);
            detectMatch(new_order);
        };

        // === detectMatch
        private func detectMatch(new_order : T.Order) {
            for (order in orders.vals()) {
                if (
                    order.id != new_order.id
                    and order.from == new_order.to
                    and order.to == new_order.from
                    and order.fromAmount == new_order.toAmount
                    and order.toAmount == new_order.fromAmount,
                ) {
                    // call processTrade
                    processTrade(order, new_order);
                };
            };
        };

        // === processTrade
        private func processTrade(order_x : T.Order, order_y : T.Order) {
            // 残高を更新する
            let _removed_x = balance_book.removeToken(order_x.owner, order_x.from, order_x.fromAmount);
            balance_book.addToken(order_x.owner, order_x.to, order_x.toAmount);
            // 取引の内容で`order_y`のトークン残高を更新
            let _removed_y = balance_book.removeToken(order_y.owner, order_y.from, order_y.fromAmount);
            balance_book.addToken(order_y.owner, order_y.to, order_y.toAmount);

            // 取引成立後に削除
            let _removed_order_x = orders.remove(order_x.id);
            let _removed_order_y = orders.remove(order_y.id);
        };
    };

};