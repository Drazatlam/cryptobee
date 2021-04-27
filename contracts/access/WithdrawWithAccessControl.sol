
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./AccessControl.sol";
import "../utils/Address.sol";


abstract contract WithdrawWithAccessControl is AccessControl{
    using Address for address;
    using Address for address payable;
    
    bytes32 public constant withdrawRole =  keccak256("WithdrawWithAccessControl");
    
    function withdrawAll() external onlyRole(withdrawRole) returns(uint256){
        WithdrawWithAccessControl[] memory subs = subWithdraw();
        for(uint256 i = 0; i < subs.length; i++){
            subs[i].withdrawAll();
        }
        return _withdraw(2**256-1);
    }
    
    function withdraw(uint256 maxAmount) external onlyRole(withdrawRole) returns(uint256){
        return _withdraw(maxAmount);
    }
    
    function subWithdraw() public virtual view returns(WithdrawWithAccessControl[] memory){
        return new WithdrawWithAccessControl[](0);
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