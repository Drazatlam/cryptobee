
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "../utils/Address.sol";


abstract contract Withdraw is Ownable{
    using Address for address;
    using Address for address payable;
    
    function withdrawAll() external onlyOwner returns(uint256){
        Withdraw[] memory subs = subWithdraw();
        for(uint256 i = 0; i < subs.length; i++){
            subs[i].withdrawAll();
        }
        return _withdraw(2**256-1);
    }
    
    function withdraw(uint256 maxAmount) external onlyOwner returns(uint256){
        return _withdraw(maxAmount);
    }
    
    function subWithdraw() public virtual view returns(Withdraw[] memory){
        return new Withdraw[](0);
    }
    
    function reservedAmount() public virtual view returns(uint256){
        return 0;
    }
    
     function _withdraw(uint256 maxAmount) internal returns(uint256){
        uint256 amount = address(this).balance - reservedAmount();
        if(maxAmount < amount){
            amount = maxAmount;
        }
        if(amount > 0){
            payable(owner()).sendValue(amount);
        }
        return amount;
    }
}