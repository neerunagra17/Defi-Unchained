#DeFi-Stablecoin
#DUN Stablecoin and DUNcore Contracts
Overview
This repository contains two Solidity smart contracts, DUN.sol and DUNcore.sol, which together implement a basic stablecoin system. The DUN contract defines a simple ERC20 stablecoin, while the DUNcore contract provides functionality for collateral management and minting/burning of the stablecoin tokens.

Contracts
DUN.sol
The DUN contract is an ERC20 token representing the stablecoin.

Functions
constructor: Initializes the contract by setting the token name and symbol, and minting an initial supply of 0 tokens.
mint: Allows an external caller to mint a specified amount of tokens to a specified account.
burn: Allows an external caller to burn a specified amount of tokens from a specified account.
DUNcore.sol
The DUNcore contract handles the core functionality of the stablecoin system, including depositing collateral, minting stablecoins, burning stablecoins, and redeeming collateral.

Structs
Position: Stores the collateral amount and the DUN amount for each user.
State Variables
positions: A mapping from user addresses to their respective positions.
dunToken: The address of the DUN token contract.
wethToken: The address of the WETH token contract.
wbtcToken: The address of the WBTC token contract.
wethPriceFeed: The Chainlink price feed for WETH.
wbtcPriceFeed: The Chainlink price feed for WBTC.
Constructor
Initializes the contract with the addresses of the DUN token, WETH token, WBTC token, and the respective price feeds.

Functions
depositCollateral: Allows a user to deposit collateral (WETH or WBTC) and mint a specified amount of DUN tokens.

Parameters:
token: The address of the collateral token (WETH or WBTC).
collateralAmount: The amount of collateral to deposit.
dunAmount: The amount of DUN tokens to mint.
Description:
Ensures the token is either WETH or WBTC.
Transfers the collateral from the user to the contract.
Mints DUN tokens to the user.
Updates the user's position.
burnDUNAndRedeemCollateral: Allows a user to burn DUN tokens and redeem a specified amount of collateral.

Parameters:
collateralAmount: The amount of collateral to redeem.
dunAmount: The amount of DUN tokens to burn.
Description:
Ensures the user has enough DUN tokens to burn.
Burns the specified amount of DUN tokens.
Calculates the collateral to redeem based on the DUN amount.
Ensures the contract has enough collateral to redeem.
Transfers the collateral to the user.
Updates the user's position.
liquidatePosition: Allows a user to liquidate another user's position if their health factor is below a threshold.

Parameters:
user: The address of the user to liquidate.
debtAmount: The amount of debt to liquidate.
Description:
Calculates the health factor of the user.
If the health factor is below a threshold, performs liquidation by transferring the debt amount and a liquidation bonus to the caller, and adjusts the user's position.
calculateHealthFactor: Calculates the health factor of a user's position.

Parameters:
user: The address of the user.
Returns:
The health factor, calculated as the collateral value divided by the DUN value.
getPriceInUSD: Retrieves the price of a token in USD from the Chainlink price feed.

Parameters:
token: The address of the token (WETH or WBTC).
Returns:
The price of the token in USD.
