// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/ERC721WithAccessControl.sol";
import "./Honey.sol";
import "./Bee.sol";
import "../token/ERC721/utils/WithdrawERC721.sol";

contract Hive is WithdrawERC721{
    using Address for address;
    using Address for address payable;
    
    bytes32 public constant hiveManagerRole =  keccak256("Hive/hiveManager");
    
    Honey internal honey;
    Bee internal bee;
    uint256 baseClaimPrice;
    uint128 internal hiveSize = 0;
    uint256 public honeyTime;
    uint256 public honeyCooldown;
    
    constructor(address beeAdress_, address honeyAdress_, uint256 baseClaimPrice_, uint256 honeyCooldown_){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        bee = Bee(beeAdress_);
        require(bee.isBee());
        honey = Honey(honeyAdress_);
        require(honey.isHoney());
        honeyCooldown = honeyCooldown_;
        honeyTime = (block.timestamp / honeyCooldown) * honeyCooldown + honeyCooldown;
        baseClaimPrice = baseClaimPrice_;
    }
    
    function setup(string memory firstBeeName_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _createBee(firstBeeName_, 0, 0);
    }
    
    function enlargeHive() external virtual onlyRole(DEFAULT_ADMIN_ROLE){
        require(canEnlargeHive());
        hiveSize++;
    }
    
    function createBee(string memory name, int128 x, int128 z) external onlyRole(hiveManagerRole){
        _createBee(name, x, z);
    }
    
    function createBees(string[] memory names, int128[] memory xs, int128[] memory zs) external onlyRole(hiveManagerRole){
        require(names.length == xs.length);
        require(names.length == zs.length);
        for(uint256 i = 0; i < names.length; i++){
            _createBee(names[i], xs[i], zs[i]);
        }
    }
    
    function canEnlargeHive() public view returns(bool){
        uint128 newSize = hiveSize + 1;
         for(int128 x = -int128(newSize); x <= int128(newSize); x++){
            for(int128 z = -int128(newSize); z <= int128(newSize); z++){
                uint256 distance = distanceToCenter(x, z);
                if(distance <= newSize && !bee.exists(positionToId(x, z))){
                    return false;
                }
            }
        }
        return true;
    }
    
    function dispatchHoney() external returns(uint256){
        require(block.timestamp > honeyTime);
        honeyTime += honeyCooldown;
        honey.mint(_msgSender(), 10);
        return _dispatchHoney() + 10;
        
    }
    
    function claimableBee() public view returns(uint256[] memory){
        //TODO
        return allBee(address(this));
    }
    
    function allBee() public view returns(uint256[] memory){
        return allBee(address(0));
    }
    
    function activBee() public view returns(uint256){
        return (hiveSize + 1) * hiveSize + 1;
    }
    
    function allBee(address beeOwner) public view returns(uint256[] memory){
        uint256 size;
        if(beeOwner == address(0)){
            size = activBee();
        }
        else{
            size = bee.balanceOf(beeOwner);
        }
        uint256[] memory result = new uint256[](size);
        uint256 count = 0;
        for(int128 x = -int128(hiveSize); (x <= int128(hiveSize) && count < size); x++){
            for(int128 z = -int128(hiveSize); (z <= int128(hiveSize) && count < size); z++){
                uint256 beeId = positionToId(x,z);
                if(bee.exists(beeId)){
                    if(beeOwner == address(0) || beeOwner == bee.ownerOf(beeId)){
                        result[count++] = beeId;
                    }
                }
            }
        }
        return result;
    }
    
    function renameBee(uint256 beeId, string memory newName) external senderIsOwner(beeId){
        bee.renameBee(beeId, newName);
    }
    
    function claimBee(uint256 beeId) external payable{
        _claimBeeFor(beeId, _msgSender());
    }
    
    function claimBeeFor(uint256 beeId, address to) external payable{
       _claimBeeFor(beeId, to);
    }
    
    function factor(uint256 beeId) public view returns(uint256){
        uint256 f = distanceToCenter(beeId);
        if(f > hiveSize){
            return 0;
        }
        else {
            return hiveSize - f;
        }
    }
    
    function price(uint256 fact) public view returns(uint256){
        return baseClaimPrice * (2**fact);
    }
    
    function idToPositon(uint256 id) public pure returns(int128, int128){
        return (int128(uint128(id >> 128)), int128(uint128(id)));
    }
    
    function positionToId(int128 x, int128 z) public pure returns(uint256){
        return (uint256(uint128(x)) << 128) + uint256(uint128(z)); 
    }
    
    function distanceToCenter(uint256 id) public pure returns(uint256){
        (int128 x, int128 z) = idToPositon(id);
        return distanceToCenter(x, z);
    } 
    
    function distanceToCenter(int128 x, int128 z) public pure returns(uint256){
        int128 y = - x - z;
        x = x > 0 ? x : -x;
        y = y > 0 ? y : -y;
        z = z > 0 ? z : -z;
        return uint128(x > y ? (x > z ? x : z) : (y > z ? y : z));
    } 
    
    modifier senderIsOwner(uint256 id){
        require(_msgSender() == bee.ownerOf(id));
        _;
    }
    
    function _createBee(string memory name, int128 x, int128 z) private{
        uint256 id = positionToId(x,z);
        bee.mintBee(address(this), id, name);
    }
    
    function _claimBeeFor(uint256 beeId, address to) internal{
        require(bee.ownerOf(beeId) == address(this));
        uint256 fact = factor(beeId);
        uint256 pri = price(fact);
        require(msg.value >= pri);
        if(msg.value > pri){
            payable(_msgSender()).sendValue(msg.value - pri);
        }
        
        bee.safeTransfer(address(this), to, beeId, "");
        honey.mint(to,fact+1);
    }
    
    function _enlargeHive() internal{
        require(canEnlargeHive());
        hiveSize++;
    }
    
    function _dispatchHoney() internal virtual returns(uint256){
        uint256 total = 0;
        for(int128 x = -int128(hiveSize); x <= int128(hiveSize) ; x++){
            for(int128 z = -int128(hiveSize); z <= int128(hiveSize); z++){
                uint256 beeId = positionToId(x,z);
                address realOwner = bee.realOwnerOfBee(beeId);
                if(realOwner != address(0)){
                    uint256 fact = factor(beeId);
                    honey.mint(realOwner, fact + 1);
                    total += (fact + 1);
                }
            }
        }
        return total;
    }

    function reservedERC721(IERC721, uint256) public virtual override view returns(bool){
        return false;
    }
}