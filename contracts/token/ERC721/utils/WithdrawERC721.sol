
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../IERC721.sol";
import "../../../access/AccessControl.sol";
import "../../../utils/Address.sol";
import "../IERC721Receiver.sol";


abstract contract WithdrawERC721 is AccessControl, IERC721Receiver{
    using Address for address;
    
    bytes32 public constant withdrawERC721Role =  keccak256("WithdrawERC721WithAccessControl");
    
    function withdrawERC721(address add, uint256 id) external onlyRole(withdrawERC721Role){
        _withdrawERC721(add, id);
    }
    
    function _withdrawERC721(address add, uint256 id) internal{
        require(add.isContract());
        IERC721 token = IERC721(add);
        require(!reservedERC721(token, id));
        token.safeTransferFrom(address(this),_msgSender(), id );
    }
    
    function reservedERC721(IERC721 token, uint256 id) public virtual view returns(bool);
    
    function onERC721Received(address, address, uint256, bytes calldata) external override virtual returns (bytes4){
        return this.onERC721Received.selector;
    }

}