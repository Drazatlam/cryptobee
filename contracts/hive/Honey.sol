// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/ERC20WithAccessControl.sol";

contract Honey is ERC20WithAccessControl{
    constructor() ERC20WithAccessControl("Honey", "HNY"){}
    
    function isHoney() external pure returns(bool){
        return true;
    }
}