// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MovieRatingToken is ERC20 {
    uint256 private constant INITIAL_SUPPLY = 1000;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}
