// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/ERC721WithAccessControl.sol";

contract Bee is ERC721WithAccessControl{
    using Address for address;
    using Address for address payable;
    
    struct BeeInfo{
        string name;
    }
    mapping(uint256 => BeeInfo) public bees;
    
    constructor() ERC721WithAccessControl("Bee", "BEE"){
    }
    
    function renameBee(uint256 beeId, string memory newName) external onlyRole(mintRole){
        bees[beeId].name = newName;
    }
    
    function exists(uint256 beeId) external view returns (bool) {
        return _exists(beeId);
    }
    
    function mint(address, uint256) external pure override{
        require(false);
    }
    
    function isBee() external pure returns(bool){
        return true;
    }
    
    function mintBee(address to, uint256 tokenId, string memory beeName) external virtual onlyRole(mintRole){
        _mint(to, tokenId);
        bees[tokenId] = BeeInfo(beeName);
    }
    
    function realOwnerOfBee(uint256 beeId) external view returns(address){
        if(!_exists(beeId)){
            return address(0);
        }
        address ownerOfBee = ownerOf(beeId);
        if(_delegateOwners[ownerOf(beeId)]){
            address owner = IDelegateERC721Owner(ownerOfBee).ownerOf(address(this), beeId);
            if(owner != address(0)){
                return owner;
            }
        }
        return ownerOfBee;
        
    }
}