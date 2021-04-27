
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../IERC20.sol";
import "../../../access/AccessControl.sol";
import "../../../utils/Address.sol";


abstract contract WithdrawERC20WithAccessControl is AccessControl{
    using Address for address;
    bytes32 public constant withdrawERC20Role =  keccak256("WithdrawERC20WithAccessControl");
    
    function withdrawAllERC20(address add) external onlyRole(withdrawERC20Role) returns(uint256){
        WithdrawERC20WithAccessControl[] memory subs = subWithdrawERC20();
        for(uint256 i = 0; i < subs.length; i++){
            subs[i].withdrawAllERC20(add);
        }
        return _withdrawERC20(add, 2**256-1);
    }
    
    function subWithdrawERC20() public virtual view returns(WithdrawERC20WithAccessControl[] memory){
        return new WithdrawERC20WithAccessControl[](0);
    }
    
    function reservedERC20Amount(IERC20) public virtual view returns(uint256){
        return 0;
    }
    
    function withdrawERC20(address add, uint256 maxAmount) external onlyRole(withdrawERC20Role) returns(uint256){
        return _withdrawERC20(add, maxAmount);
    }
    
    function _withdrawERC20(address add, uint256 maxAmount) internal returns(uint256){
        require(add.isContract());
        IERC20 token = IERC20(add);
        uint256 amount = token.balanceOf(address(this)) - reservedERC20Amount(token);
        if(maxAmount < amount){
            amount = maxAmount;
        }
        if(amount > 0){
            token.transfer(_msgSender(), amount );
        }
        return amount;
    }
}