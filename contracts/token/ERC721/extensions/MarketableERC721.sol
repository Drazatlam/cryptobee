// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../IERC721.sol";
import "../utils/WithdrawERC721.sol";
import "../../ERC20/IERC20.sol";
import "../../ERC20/utils/WithdrawERC20.sol";
import "../../ERC20/extensions/OwnableERC20.sol";
import "../../../access/Ownable.sol";
import "../../../access/Withdraw.sol";

contract MarketableERC721 is ERC721, Ownable, Withdraw, WithdrawERC20, WithdrawERC721{
    using Address for address;
    using Address for address payable;
    
    struct Order{
        bool sell;
        address owner;
        bool withToken;
        uint256 amount;
        uint256 tokenId;
    }
    
    OwnableERC20 fungibleToken;
    
    uint256 nextId = 1;
    mapping(uint256 => Order) orders;
    
    uint256 private _reservedAmount = 0;
    uint256 private _reservedERC20;
    mapping(uint256 => address) _reservedToken;
    
    constructor (string memory name_, string memory symbol_, address tokenAdress) ERC721(name_, symbol_){
        fungibleToken = OwnableERC20(tokenAdress);
    }
    
    function placeSellOrder(uint256 tokenId, uint256 amount) public returns(uint256){
        return _placeOrder(true, false, amount, tokenId);
    }
    
    function placeTokenSellOrder(uint256 tokenId, uint256 amount) public returns(uint256){
        return _placeOrder(true, true, amount, tokenId);
    }
    
    function placeBuyOrder(uint256 tokenId, uint256 amount) public returns(uint256){
        return _placeOrder(false, false, amount, tokenId);
    }
    
    function placeTokenbuyOrder(uint256 tokenId, uint256 amount) public returns(uint256){
        return _placeOrder(false, true, amount, tokenId);
    }
    
    function removeOrder(uint256 orderId) public{
        require(orders[orderId].owner == _msgSender());
        _removeOrder(orderId, true);
    }
    
    function tokenOrder(uint256 tokenId, bool withToken) external view returns(uint256[] memory){
        return _tokenOrder(tokenId, withToken);
    }
    
    function addressOrder(address add, bool withToken) external view returns(uint256[] memory){
        return _addressOrder(add, withToken);
    }
    
    function reservedAmount() public override view returns(uint256){
        return _reservedAmount;
    }
    
    function reservedERC20Amount(IERC20 token) public override view returns(uint256){
        if(address(fungibleToken) == address(token)){
            return _reservedERC20;
        }
        else {
            return 0;
        }
    }
    
    function reservedERC721(IERC721 token, uint256 id) public override view returns(bool){
        if(address(token) == address(this)){
            return _reservedToken[id] != address(0);
        }
        else {
            return false;
        }
    }
    
    function _sell(uint256 orderId) private{
        require(orders[orderId].owner != address(0));
        require(!orders[orderId].sell);
        
        _safeTransfer(_msgSender(), orders[orderId].owner, orders[orderId].tokenId, "");
        if(orders[orderId].withToken){
            fungibleToken.transfer(_msgSender(), orders[orderId].amount - orders[orderId].amount / 11);
            _reservedERC20 -= orders[orderId].amount;
        }
        else{
            payable(_msgSender()).sendValue(orders[orderId].amount - orders[orderId].amount / 11);
            _reservedAmount -= orders[orderId].amount;
        }
        _removeOrder(orderId, false);
    }
    
    function _buy(uint256 orderId) private{
        require(orders[orderId].owner != address(0));
        require(orders[orderId].sell);
            
        _safeTransfer(orders[orderId].owner, _msgSender(), orders[orderId].tokenId, "");
        delete _reservedToken[orders[orderId].tokenId];
        if(orders[orderId].withToken){
            if(orders[orderId].amount / 10 > 0){
                fungibleToken.forceTransfer(_msgSender(), address(this), orders[orderId].amount / 10);
            }
            fungibleToken.forceTransfer(_msgSender(), orders[orderId].owner, orders[orderId].amount);
        }
        else{
            require(msg.value == orders[orderId].amount + orders[orderId].amount / 10);
            payable(orders[orderId].owner).sendValue(orders[orderId].amount);
        }
        _removeOrder(orderId, false);
    }
    
    function _removeOrder(uint256 orderId, bool refund) private{
        if(refund){
            if (orders[orderId].sell){
                _safeTransfer(address(this), orders[orderId].owner, orders[orderId].tokenId, "");
                delete _reservedToken[orders[orderId].tokenId];
            }
            else {
                if(orders[orderId].withToken){
                    fungibleToken.forceTransfer(address(this), orders[orderId].owner, orders[orderId].amount);
                    _reservedERC20 -= orders[orderId].amount;
                }
                else{
                    payable(orders[orderId].owner).sendValue(orders[orderId].amount);
                    _reservedAmount -= orders[orderId].amount;
                }
            }
        }
        delete orders[orderId];
    }
    
    function _placeOrder(bool sell, bool withToken, uint256 amount, uint256 tokenId) private returns(uint256){
        require(amount > 0);
        orders[nextId++] = Order(sell, _msgSender(), withToken, amount, tokenId);
        if(sell){
            require(_reservedToken[tokenId] == address(0));
            _safeTransfer(_msgSender(), address(this), tokenId, "");
            _reservedToken[tokenId] = _msgSender();
        }
        else{
            if(withToken){
                fungibleToken.forceTransfer(_msgSender(), address(this), amount);
                _reservedERC20 += amount;
            }
            else{
                require(msg.value == amount);
                _reservedAmount += amount;
            }
        }
        return nextId - 1;
    }
    
    function _tokenOrder(uint256 tokenId, bool withToken) private view returns(uint256[] memory){
        uint256 count = 0;
        for(uint256 id = 1; id < nextId; id++){
            if(orders[id].owner != address(0) && orders[id].tokenId == tokenId && orders[id].withToken == withToken ){
                count++;
            }
        }
        uint256[] memory results = new uint256[](count);
        count = 0;
        for(uint256 id = 1; id < nextId; id++){
            if(orders[id].owner != address(0) && orders[id].tokenId == tokenId && orders[id].withToken == withToken ){
               results[count++] = id;
            }
        }
        return results;
    }
    
    
    function _addressOrder(address add, bool withToken) private view returns(uint256[] memory){
        require(add != address(0));
        uint256 count = 0;
        for(uint256 id = 1; id < nextId; id++){
            if(orders[id].owner == add && orders[id].withToken == withToken ){
                count++;
            }
        }
        uint256[] memory results = new uint256[](count);
        count = 0;
        for(uint256 id = 1; id < nextId; id++){
            if(orders[id].owner == add && orders[id].withToken == withToken ){
               results[count++] = id;
            }
        }
        return results;
    }
    
}