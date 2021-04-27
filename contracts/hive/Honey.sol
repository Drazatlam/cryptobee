// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/MarketableERC20.sol";

contract Honey is MarketableERC20{
    constructor() MarketableERC20("Honey", "HNY"){}
}