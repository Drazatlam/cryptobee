// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Hive.sol";
contract UpgradableHive is Hive{
    
    uint256 enlargeBasePrice;
    uint256 public collectedAmountForEnlarge = 0;
    address[] public partipantToEnlarge;
    mapping(address => uint256) public partipationToEnlarge;
    
    
    constructor(address honeyAdress_, string[] memory firstBeesName_, uint128 hiveSize_, uint256 baseClaimPrice_, uint256 honeyCooldown_, uint256 enlargeBasePrice_)
    Hive(honeyAdress_, firstBeesName_, hiveSize_, baseClaimPrice_, honeyCooldown_){
        require(enlargeBasePrice_ > 0);
        enlargeBasePrice = enlargeBasePrice_;
    }
    
    function enlargePrice() public view returns(uint256){
        return enlargeBasePrice * (2**hiveSize);
    }
    
    function participateToEnlargeHive(uint256 amount) external{
        uint256 remaining = enlargePrice() - collectedAmountForEnlarge;
        if(amount > remaining){
            amount = remaining;
        }
        require(amount > 0);
        honey.forceTransfer(_msgSender(),address(this), amount);
        honey.burn(address(this), amount - amount / 10);
        collectedAmountForEnlarge += amount;
        partipantToEnlarge.push(_msgSender());
        partipationToEnlarge[_msgSender()] += amount;
    }
    
    function enlarge(string[] memory beeNames) public onlyOwner{
        require(collectedAmountForEnlarge == enlargePrice());
        _enlargeHive(hiveSize + 1, beeNames, 0);
        collectedAmountForEnlarge = 0;
        for(uint256 i = 0; i < partipantToEnlarge.length; i++){
            delete partipationToEnlarge[partipantToEnlarge[i]];
        }
        delete partipantToEnlarge;
        
    }
    
}