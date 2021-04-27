
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./AccessControl.sol";
import "../utils/Address.sol";


abstract contract Withdraw is AccessControl{
    using Address for address;
    using Address for address payable;
    
    bytes32 public constant withdrawRole =  keccak256("WithdrawWithAccessControl");
    
    function withdrawAll() external onlyRole(withdrawRole) returns(uint256){
        uint256 value = withdrawAllUnckecked();
        require(value > 0);
        return value;
    }
    
    function withdrawAllUnckecked() public onlyRole(withdrawRole) returns(uint256){
        Withdraw[] memory subs = subWithdraw();
        for(uint256 i = 0; i < subs.length; i++){
            subs[i].withdrawAllUnckecked();
        }
        return _withdraw(type(uint256).max);
    }
    
    function withdraw(uint256 maxAmount) external onlyRole(withdrawRole) returns(uint256){
        uint256 value = _withdraw(maxAmount);
        require(value > 0);
        return value;
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
            payable(_msgSender()).sendValue(amount);
        }
        return amount;
    }
}