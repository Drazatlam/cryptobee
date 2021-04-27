// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/MarketableERC721.sol";
import "./Honey.sol";

contract Hive is MarketableERC721{
    using Address for address;
    using Address for address payable;
    
    struct Bee{
        string name;
    }
    
    Honey internal honey;
    mapping(uint256 => Bee) public bees;
    uint256 baseClaimPrice;
    uint128 internal hiveSize = 0;
    uint256 totalBee = 0;
    uint256 public honeyTime;
    uint256 public honeyCooldown;
    
    constructor(address honeyAdress_, string[] memory firstBeesName_, uint128 hiveSize_, uint256 baseClaimPrice_, uint256 honeyCooldown_) MarketableERC721("Bee", "BEE", honeyAdress_){
        honey = Honey(honeyAdress_);
        honeyCooldown = honeyCooldown_;
        honeyTime = (block.timestamp / honeyCooldown) * honeyCooldown + honeyCooldown;
        baseClaimPrice = baseClaimPrice_;
        _createBee(firstBeesName_[0], 0, 0);
        if(hiveSize_ > 0){
            _enlargeHive(hiveSize_, firstBeesName_, 1);
        }
    }
    
    function dispatchHoney() external returns(uint256){
        require(block.timestamp > honeyTime);
        honeyTime += honeyCooldown;
        honey.mint(_msgSender(), 10);
        return _dispatchHoney() + 10;
        
    }
    
    function claimableBee() public view returns(uint256[] memory){
        uint256[] memory ownedBees = allBee(address(this));
        uint256 count = 0;
        for(uint256 i = 0; i < ownedBees.length; i++){
            if(_reservedToken[ownedBees[i]] == address(0)){
                count++;
            }
        }
        
        uint256[] memory result = new uint256[](count);
        count = 0;
        for(uint256 i = 0; i < ownedBees.length; i++){
            if(_reservedToken[ownedBees[i]] == address(0)){
                result[count++] = ownedBees[i];
            }
        }
        return result;
    }
    
    function allBee() public view returns(uint256[] memory){
        return allBee(address(0));
    }
    
    function allBee(address beeOwner) public view returns(uint256[] memory){
        uint256[] memory result;
        if(beeOwner == address(0)){
            result = new uint256[](totalBee);
        }
        else{
            result = new uint256[](balanceOf(beeOwner));
        }
        uint256 count = 0;
        for(int128 x = -int128(hiveSize); (x <= int128(hiveSize) && count < result.length); x++){
            for(int128 z = -int128(hiveSize); (z <= int128(hiveSize) && count == result.length); z++){
                uint256 beeId = positionToId(x,z);
                if(_exists(beeId)){
                    if(beeOwner == address(0) || beeOwner == ownerOf(beeId)){
                        result[count++] = beeId;
                    }
                }
            }
        }
        return result;
    }
    
    function renameBee(uint256 beeId, string memory newName) external senderIsOwner(beeId){
        bees[beeId].name = newName;
    }
    
    function claimBee(uint256 beeId) external payable{
        _claimBeeFor(beeId, _msgSender());
    }
    
    function claimBeeFor(uint256 beeId, address to) external payable{
       _claimBeeFor(beeId, to);
    }
    
    function beePriceInfo(uint256 beeId) public view returns(uint256, uint256){
        uint256 factor = distanceToCenter(beeId);
        if(factor > hiveSize){
            factor = 0;
        }
        else {
            factor = hiveSize - factor;
        }
        return (factor, baseClaimPrice * (2**factor));
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
        require(_msgSender() == ownerOf(id));
        _;
    }
    
    function _createBee(string memory name, int128 x, int128 z) private{
        uint256 id = positionToId(x,z);
        _mint(address(this), id);
        bees[id] = Bee(name);
        totalBee++;
    }
    
    function _claimBeeFor(uint256 beeId, address to) internal{
        require(ownerOf(beeId) == address(this));
        require(_reservedToken[beeId] == address(0));
        (uint256 factor, uint256 price) = beePriceInfo(beeId);
        require(msg.value >= price);
        if(msg.value > price){
            payable(_msgSender()).sendValue(msg.value - price);
        }
        
        safeTransferFrom(address(this), to, beeId);
        honey.mint(to,factor+1);
    }
    
    function _enlargeHive(uint128 newSize, string[] memory newBees, uint256 offset) internal{
        require(newSize > hiveSize);
        require(int128(newSize) > 0);
        require(newBees.length - offset == (hiveSize+1+newSize)*(newSize-hiveSize)/2*6);
        for(int128 x = -int128(newSize); x <= int128(newSize); x++){
            for(int128 z = -int128(newSize); z <= int128(newSize); z++){
                uint256 distance = distanceToCenter(x, z);
                if(distance > hiveSize && distance <= newSize){
                    _createBee(newBees[offset++],x,z);
                }
            }
        }
        hiveSize = newSize;
    }
    
    function _realOwnerOfBee(uint256 beeId) internal view returns(address){
        if(!_exists(beeId)){
            return address(0);
        }
        if(ownerOf(beeId) == address(this)){
            return _reservedToken[beeId];
        }
        else{
            return ownerOf(beeId);
        }
    }
    
    function _dispatchHoney() internal virtual returns(uint256){
        uint256 total = 0;
        for(int128 x = -int128(hiveSize); x <= int128(hiveSize) ; x++){
            for(int128 z = -int128(hiveSize); z <= int128(hiveSize); z++){
                uint256 beeId = positionToId(x,z);
                address realOwner = _realOwnerOfBee(beeId);
                if(realOwner != address(0)){
                    (uint256 factor,) = beePriceInfo(beeId);
                    honey.mint(realOwner, factor + 1);
                    total += (factor + 1);
                }
            }
        }
        return total;
    }
    
    function subWithdraw() public virtual override view returns(Withdraw[] memory){
        Withdraw[] memory subs =  new Withdraw[](1);
        subs[0] = Withdraw(honey);
        return subs;
    }
    
    function subWithdrawERC20() public virtual override view returns(WithdrawERC20[] memory){
        WithdrawERC20[] memory subs =  new WithdrawERC20[](1);
        subs[0] = WithdrawERC20(honey);
        return subs;
    }
}