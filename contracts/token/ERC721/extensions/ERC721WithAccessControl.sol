// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../IERC721.sol";
import "../../../access/AccessControl.sol";
import "../../../utils/introspection/IERC165.sol";

interface IDelegateERC721Owner is IERC165{
    function ownerOf(address tokenAddress, uint256 tokenId) external view returns(address);
}

interface IERC721WithAccessControl is IERC721{
    function mint(address to, uint256 tokenId) external ;
    function burn(uint256 tokenId) external ;
    function safeTransfer(address from, address to, uint256 tokenId, bytes memory data) external ;
    function registerDelegateERC721Owner() external;
    
}

contract ERC721WithAccessControl is ERC721, AccessControl, IERC721WithAccessControl{
 
    constructor (string memory name_, string memory symbol_) ERC721(name_, symbol_){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
 
    bytes32 public constant mintRole =  keccak256("ERC721WithAccessControl/mint");
    bytes32 public constant burnRole =  keccak256("ERC721WithAccessControl/burn");
    bytes32 public constant transferRole =  keccak256("ERC721WithAccessControl/transfer");
    
    mapping(address => bool) internal _delegateOwners;
    
    
    function mint(address to, uint256 tokenId) external override onlyRole(mintRole){
        _mint(to, tokenId);
    }
    
    function burn(uint256 tokenId) external override onlyRole(burnRole){
        _burn(tokenId);
    }
    
    function safeTransfer(address from, address to, uint256 tokenId, bytes memory data) external override onlyRole(transferRole){
        _safeTransfer(from, to, tokenId, data);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl, IERC165) returns (bool) {
        return  ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId) || interfaceId == type(IERC721WithAccessControl).interfaceId;
    }
    
    function registerDelegateERC721Owner() external override{
        IDelegateERC721Owner delegate = IDelegateERC721Owner(_msgSender());
        require(delegate.supportsInterface(type(IDelegateERC721Owner).interfaceId));
        _delegateOwners[_msgSender()] = true;
    }
    
    
}