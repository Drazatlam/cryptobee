// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../access/AccessControl.sol";

contract ERC721WithAccessControl is ERC721, AccessControl{
 
    constructor (string memory name_, string memory symbol_) ERC721(name_, symbol_){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
 
    bytes32 public constant mintRole =  keccak256("ERC721WithAccessControl/mint");
    bytes32 public constant burnRole =  keccak256("ERC721WithAccessControl/burn");
    bytes32 public constant transferRole =  keccak256("ERC721WithAccessControl/transfer");
    
    
    function mint(address to, uint256 tokenId) external onlyRole(mintRole){
        _mint(to, tokenId);
    }
    
    function burn(uint256 tokenId) external onlyRole(burnRole){
        _burn(tokenId);
    }
    
    function safeTransfer(address from, address to, uint256 tokenId, bytes memory data) external onlyRole(transferRole){
        _safeTransfer(from, to, tokenId, data);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return  ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }
    
    
}