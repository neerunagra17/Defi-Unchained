// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DUN is ERC20 {
    constructor() ERC20("DUN Stablecoin", "DUN") {
        _mint(msg.sender, 0); // Initial supply, can be minted upon collateral deposit
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}