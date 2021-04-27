// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../access/Ownable.sol";

contract OwnableERC20 is ERC20, Ownable {
    
    constructor (string memory name_, string memory symbol_) ERC20(name_, symbol_) {}
    
    function mint(address account, uint256 amount) public onlyOwner{
        _mint(account, amount);
    }
    
    function burn(address account, uint256 amount) public onlyOwner{
        _burn(account, amount);
    }
    
    function decimals() public pure override returns(uint8) {
        return 0;
    }
    
    function forceTransfer(address from, address to, uint256 amount) public onlyOwner{
        _transfer(from, to, amount);
    }
}