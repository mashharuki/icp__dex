#!/bin/bash

dfx identity use default

# ==== デプロイをするユーザプリンシパル（識別子）を変数に登録するコマンド =====
export ROOT_PRINCIPAL=$(dfx identity get-principal)

# ===== CREATE demo user =====
dfx identity new --disable-encryption user1
dfx identity use user1
export USER1_PRINCIPAL=$(dfx identity get-principal)

dfx identity new --disable-encryption user2
dfx identity use user2
export USER2_PRINCIPAL=$(dfx identity get-principal)

# Set default user
dfx identity use default

# ===== deploy Token Canister =====
dfx deploy GoldDIP20 --argument='("Token Gold Logo", "Token Silver", "TGLD", 8, 10_000_000_000_000_000, principal '\"$ROOT_PRINCIPAL\"', 0)'
dfx deploy SilverDIP20 --argument='("Token Silver Logo", "Token Silver", "TSLV", 8, 10_000_000_000_000_000, principal '\"$ROOT_PRINCIPAL\"', 0)'

export GoldDIP20_PRINCIPAL=$(dfx canister id GoldDIP20)
export SilverDIP20_PRINCIPAL=$(dfx canister id SilverDIP20)

# ===== deploy faucet Canister =====
dfx deploy faucet
export FAUCET_PRINCIPAL=$(dfx canister id faucet)

# Pooling tokens
dfx canister call GoldDIP20 mint '(principal '\"$FAUCET_PRINCIPAL\"', 100_000)'
dfx canister call SilverDIP20 mint '(principal '\"$FAUCET_PRINCIPAL\"', 100_000)'

# ===== TEST faucet =====
echo -e '\n\n#------ faucet ------------'
dfx identity use user1
echo -n "getToken    >  " \
  && dfx canister call faucet getToken '(principal '\"$GoldDIP20_PRINCIPAL\"')'
echo -n "balanceOf   >  " \
  && dfx canister call GoldDIP20 balanceOf '(principal '\"$USER1_PRINCIPAL\"')'

echo -e '#------ faucet { Err = variant { AlreadyGiven } } ------------'
dfx canister call faucet getToken '(principal '\"$GoldDIP20_PRINCIPAL\"')'

echo -e
dfx identity use user2
echo -n "getTOken    >  " \
  && dfx canister call faucet getToken '(principal '\"$SilverDIP20_PRINCIPAL\"')'
echo -n "balanceOf   >  " \
  && dfx canister call SilverDIP20 balanceOf '(principal '\"$USER2_PRINCIPAL\"')'


# ===== 削除 =====
dfx identity use default
dfx identity remove user1
dfx identity remove user2