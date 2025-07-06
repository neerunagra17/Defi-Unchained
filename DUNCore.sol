// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/DUN.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Stablecore {
    struct UserCollateral {
        uint256 ethCollateral;
        uint256 btcCollateral;
        uint256 stableTokenAmount;
    }

    mapping(address => UserCollateral) public userCollaterals;

    address public immutable stableToken;
    address public immutable ethToken;
    address public immutable btcToken;
    AggregatorV3Interface public ethPriceFeed;
    AggregatorV3Interface public btcPriceFeed;

    
    uint256 public constant BONUS_FOR_LIQUIDATION = 10; // 10% bonus for liquidators
    uint256 public constant COLLATERAL_THRESHOLD = 150; // 150% collateralization

    constructor(
        address _stableToken,
        address _ethToken,
        address _btcToken,
        address _ethPriceFeed,
        address _btcPriceFeed
    ) {
        stableToken = _stableToken;
        ethToken = _ethToken;
        btcToken = _btcToken;
        ethPriceFeed = AggregatorV3Interface(_ethPriceFeed);
        btcPriceFeed = AggregatorV3Interface(_btcPriceFeed);
    }

    function depositAndMint(address token, uint256 collateralAmount, uint256 mintAmount) external {
        // Ensure token is ETH or BTC
        require(token == ethToken || token == btcToken, "Unsupported collateral token");

        // Transfer collateral from user to this contract
        IERC20(token).transferFrom(msg.sender, address(this), collateralAmount);

        // Update user's collateral
        UserCollateral storage collateral = userCollaterals[msg.sender];
        if (token == ethToken) {
            collateral.ethCollateral += collateralAmount;
        } else if (token == btcToken) {
            collateral.btcCollateral += collateralAmount;
        }

        collateral.stableTokenAmount += mintAmount;
        require(checkHealthFactor(msg.sender) >= COLLATERAL_THRESHOLD, "Undercollateralized");

        // Mint stable tokens to user
        DUN(stableToken).mint(msg.sender, mintAmount);
    }

    function burnAndRedeem(uint256 burnAmount, address token, uint256 collateralAmount) external {
        // Ensure token is ETH or BTC
        require(token == ethToken || token == btcToken, "Invalid collateral token");

        UserCollateral storage collateral = userCollaterals[msg.sender];
        require(collateral.stableTokenAmount >= burnAmount, "Insufficient stable token balance");
        if (token == ethToken) {
            require(collateral.ethCollateral >= collateralAmount, "Insufficient ETH collateral");
            collateral.ethCollateral -= collateralAmount;
        } else if (token == btcToken) {
            require(collateral.btcCollateral >= collateralAmount, "Insufficient BTC collateral");
            collateral.btcCollateral -= collateralAmount;
        }

        collateral.stableTokenAmount -= burnAmount;
        require(checkHealthFactor(msg.sender) >= COLLATERAL_THRESHOLD, "Undercollateralized after burn");

        // Burn stable tokens from user
        DUN(stableToken).burn(msg.sender, burnAmount);

        // Transfer collateral to user
        IERC20(token).transfer(msg.sender, collateralAmount);
    }
    
    function liquidateUser(address user, address token, uint256 debtAmount) external {
        require(token == ethToken || token == btcToken, "Invalid collateral token");

        UserCollateral storage collateral = userCollaterals[user];
        require(checkHealthFactor(user) < COLLATERAL_THRESHOLD, "Cannot liquidate a healthy position");

        uint256 liquidationBonusAmount = debtAmount + (debtAmount * BONUS_FOR_LIQUIDATION / 100);
        if (token == ethToken) {
            require(collateral.ethCollateral >= liquidationBonusAmount, "Insufficient ETH collateral for liquidation");
            collateral.ethCollateral -= liquidationBonusAmount;
        } else if (token == btcToken) {
            require(collateral.btcCollateral >= liquidationBonusAmount, "Insufficient BTC collateral for liquidation");
            collateral.btcCollateral -= liquidationBonusAmount;
        }

        collateral.stableTokenAmount -= debtAmount;

        // Burn stable tokens from user
        DUN(stableToken).burn(user, debtAmount);

        // Transfer collateral to liquidator
        IERC20(token).transfer(msg.sender, liquidationBonusAmount);
    }

    function getHealthFactor(address user) external view returns (uint256) {
        return checkHealthFactor(user);
    }

    function checkHealthFactor(address user) internal view returns (uint256) {
        UserCollateral storage collateral = userCollaterals[user];

        uint256 ethValue = getCollateralValue(collateral.ethCollateral, ethPriceFeed);
        uint256 btcValue = getCollateralValue(collateral.btcCollateral, btcPriceFeed);
        uint256 totalCollateralValue = ethValue + btcValue;

        if (collateral.stableTokenAmount == 0) {
            return type(uint256).max; // Return max value to signify healthy position (infinitely healthy)
        }

        return (totalCollateralValue * 100) / collateral.stableTokenAmount;
    }

    function getCollateralValue(uint256 amount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Price feed error"); // Ensure price is valid and positive

        return (amount * uint256(price)) / 1e8; // Assuming price feed has 8 decimals
    }
}
