
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../IERC20.sol";
import "../../../access/Ownable.sol";
import "../../../utils/Address.sol";


abstract contract WithdrawERC20 is Ownable{
    using Address for address;
    
    function withdrawAllERC20(address add) external onlyOwner returns(uint256){
        WithdrawERC20[] memory subs = subWithdrawERC20();
        for(uint256 i = 0; i < subs.length; i++){
            subs[i].withdrawAllERC20(add);
        }
        return _withdrawERC20(add, 2**256-1);
    }
    
    function subWithdrawERC20() public virtual view returns(WithdrawERC20[] memory){
        return new WithdrawERC20[](0);
    }
    
    function reservedERC20Amount(IERC20) public virtual view returns(uint256){
        return 0;
    }
    
    function withdrawERC20(address add, uint256 maxAmount) external onlyOwner returns(uint256){
        return _withdrawERC20(add, maxAmount);
    }
    
    function _withdrawERC20(address add, uint256 maxAmount) internal onlyOwner returns(uint256){
        require(add.isContract());
        IERC20 token = IERC20(add);
        uint256 amount = token.balanceOf(address(this)) - reservedERC20Amount(token);
        if(maxAmount < amount){
            amount = maxAmount;
        }
        if(amount > 0){
            token.transfer(owner(), amount );
        }
        return amount;
    }
}