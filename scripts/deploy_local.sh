#!/bin/bash

# 古いコンテンツを削除
dfx stop
rm -rf .dfx

# デプロイを行うユーザーを指定
dfx identity use default
export ROOT_PRINCIPAL=$(dfx identity get-principal)

# ローカルの実行環境を起動
dfx start --clean --background

# キャニスターをデプロイ
# ===== DIP20キャニスター =====
dfx deploy GoldDIP20 --argument='("Token Gold Logo", "Token Silver", "TGLD", 8, 10000000000000000, principal '\"$ROOT_PRINCIPAL\"', 0)'
dfx deploy SilverDIP20 --argument='("Token Silver Logo", "Token Silver", "TSLV", 8, 10000000000000000, principal '\"$ROOT_PRINCIPAL\"', 0)'
export GoldDIP20_PRINCIPAL=$(dfx canister id GoldDIP20)
export SilverDIP20_PRINCIPAL=$(dfx canister id SilverDIP20)

# ===== Internet Identityキャニスター =====
dfx deploy internet_identity_div

# ===== faucetキャニスター =====
dfx deploy faucet
export FAUCET_PRINCIPAL=$(dfx canister id faucet)
# トークンをプールする
dfx canister call GoldDIP20 mint '(principal '\"$FAUCET_PRINCIPAL\"', 100_000)'
dfx canister call SilverDIP20 mint '(principal '\"$FAUCET_PRINCIPAL\"', 100_000)'

# ===== icp_basic_dex_backend =====
dfx deploy icp__dex_backend

# ===== icp_basic_dex_frontend =====
dfx deploy icp__dex_frontend