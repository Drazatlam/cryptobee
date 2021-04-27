
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../IERC721.sol";
import "../../../access/Ownable.sol";
import "../../../utils/Address.sol";
import "../IERC721Receiver.sol";


abstract contract WithdrawERC721 is Ownable, IERC721Receiver{
    using Address for address;
    
    function withdrawERC721(address add, uint256 id) external onlyOwner{
        _withdrawERC721(add, id);
    }
    
    function _withdrawERC721(address add, uint256 id) internal onlyOwner{
        require(add.isContract());
        IERC721 token = IERC721(add);
        require(!reservedERC721(token, id));
        token.safeTransferFrom(address(this),owner(), id );
    }
    
    function reservedERC721(IERC721 token, uint256 id) public virtual view returns(bool);
    
    function onERC721Received(address, address, uint256, bytes calldata) external override virtual returns (bytes4){
        return this.onERC721Received.selector;
    }

}