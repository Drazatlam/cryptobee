// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableERC20.sol";
import "../utils/WithdrawERC20.sol";
import "../../../access/Withdraw.sol";
import "../../../utils/Address.sol";

contract MarketableERC20 is OwnableERC20, Withdraw, WithdrawERC20{
    using Address for address;
    using Address for address payable;
    
    struct Order{
        bool sell;
        address owner;
        uint256 amount;
        uint256 price;
        uint256 previous;
        uint256 next;
    }
    
    uint256 private nextId = 1;
    mapping (uint256 => Order) public orders;
    
    uint256 public firstSellId = 0;
    uint256 public firstBuyId = 0;
    
    uint256 private _reservedAmount = 0;
    uint256 private _reservedTokenAmount = 0;
    
    constructor (string memory name_, string memory symbol_) OwnableERC20(name_, symbol_) {}
    
    function sellOrders() external view returns(uint256[] memory){
        return _getOrders(true, address(0));
    }
    
    function buyOrders() external view returns(uint256[] memory){
        return _getOrders(false, address(0));
    }
    
    function addressOrders(address add) external view returns(uint256[] memory, uint256[] memory){
        return (_getOrders(true, add), _getOrders(false, add));
    }
    
    function withdrawToken() external onlyOwner returns(uint256){
        return _withdrawERC20(address(this),2**256-1);
    }
     
    function placeSellOrder(uint256 amount, uint256 price) public returns(uint256){
        require(amount > 0);
        require(price > 0);
        (, uint256 amountSold) = _sell(amount, price);
        amount -= amountSold;
        if(amount > 0){
            _transfer(_msgSender(), address(this), amount);
            _reservedTokenAmount += amount;
            return _putOrder(amount, price, true);
        }
        return 0;
    }
    
    function placeBuyOrder(uint256 amount, uint256 price) public payable returns(uint256){
        require(amount > 0);
        require(price > 0);
        require(msg.value == amount * price);
        (uint256 amountBuyed, uint256 valueBuyed) = _buyAmount(amount, price, msg.value);
        amount -= amountBuyed;
        payable(_msgSender()).sendValue(msg.value - valueBuyed - amount * price);
        if(amount > 0){
            _reservedAmount += amount * price;
            return _putOrder(amount, price, false);
        }
        
        return 0;
    }
    
    function removeOrder(uint256 orderId) public{
        require(orders[orderId].owner == _msgSender());
        _removeOrder(orderId);
    }
    
    function forceRemoveOrder(uint256 orderId) public onlyOwner{
        _removeOrder(orderId);
    }
    
    function sell(uint256 amount,uint256 minPrice, bool forceAll) public returns(uint256, uint256){
        
        (uint256 valueSold, uint256 amountSold) = _sell(amount, minPrice);
        require(valueSold > 0);
        if(forceAll){
            require(amountSold == amount);
        }
        return (valueSold, amountSold);
    }
    
    function buyAmount(uint256 amount, uint256 maxPrice, bool forceAll) public payable returns(uint256, uint256){
        (uint256 amountBuyed, uint256 valueBuyed) = _buyAmount(amount, maxPrice, msg.value);
        require(amountBuyed > 0);
        if(forceAll){
            require(amountBuyed == amountBuyed);
        }
        payable(_msgSender()).sendValue(msg.value - valueBuyed);
        return (amountBuyed, valueBuyed);
    }
    
    function buy(uint256 maxPrice) public payable returns(uint256, uint256){
        return buyAmount(2**256-1, maxPrice, false);
    }
    
    function reservedAmount() public override view returns(uint256){
        return _reservedAmount;
    }
    
    function reservedERC20Amount(IERC20 token) public override view returns(uint256){
        if(address(token) == address(this)){
            return _reservedTokenAmount;
        }
        else{
            return 0;
        }
    }
    
    function _getOrders(bool isSell, address add) private view returns(uint256[] memory){
        
        uint256 current = isSell ? firstSellId : firstBuyId;
        uint256 count = 0;
        while(current != 0){
            if(add == address(0) || add == orders[current].owner){
                count++;
            }
            current = orders[current].next;
        }
        
        uint256[] memory resultOrders = new uint256[](count);
        current = isSell ? firstSellId : firstBuyId;
        uint256 currentIndex = 0;
        while(current != 0){
            if(add == address(0) || add == orders[current].owner){
                resultOrders[currentIndex++] = current;
            }
            current = orders[current].next;
        }
        
        return resultOrders;
    }
    
    function _putOrder(uint256 amount, uint256 price, bool isSell) private returns(uint256){
        
        Order memory order = Order(isSell, _msgSender(), amount, price, 0, 0);
         
        uint256 id = nextId++;
        orders[id] = order;
        
        uint256 prev = 0;
        uint256 current = isSell ? firstSellId : firstBuyId;
        while(current !=0 && (isSell ? (orders[current].price <= price) : (orders[current].price >= price))){
            prev = current;
            current = orders[current].next;
        }
        
        orders[id].previous = prev;
        orders[id].next = current;
        if(prev == 0){
            if(isSell){
                firstSellId = id;
            }
            else{
                firstBuyId = id;
            }
        }
        else{
            orders[prev].next = id;
        }
        
        if(current != 0){
            orders[current].previous = id;
        }
        
        return id;
        
    }
    
    function _removeOrder(uint256 orderId) private{
        Order storage order = orders[orderId];
        if(order.previous == 0){
            if(order.sell){
                firstSellId = order.next;
            }
            else{
                firstBuyId =order.next;
            }
        }
        else {
            orders[order.previous].next = order.next;
        }
        
        if(order.next !=0){
            orders[order.next].previous = order.previous;
        }
        delete orders[orderId];
        
        if(order.sell){
            _transfer(address(this), order.owner, order.amount);
            _reservedTokenAmount -= order.amount;
        }
        else{
            payable(order.owner).sendValue(order.amount);
            _reservedAmount -= order.amount;
        }
    }
    
    function _sell(uint256 amount,uint256 minPrice) private returns(uint256, uint256){
        require(amount > 0);
        require(minPrice > 0);
        uint256 total = 0;
        uint256 remainingAmount = amount;
        uint256 current = firstBuyId;
        while(current != 0 && remainingAmount != 0){
            Order storage currentOrder = orders[current];
            if(currentOrder.owner != _msgSender()){
                if(currentOrder.price < minPrice){
                    break;
                }
                if(currentOrder.amount < remainingAmount){
                    remainingAmount -= currentOrder.amount;
                    total += currentOrder.amount * currentOrder.price;
                    _transfer(_msgSender(), currentOrder.owner, currentOrder.amount);
                    _removeOrder(current);
                }
                else {
                    total += remainingAmount * currentOrder.price;
                    remainingAmount = 0;
                    currentOrder.amount -= remainingAmount;
                    _transfer(_msgSender(), currentOrder.owner, remainingAmount);
                }
            }
            current = currentOrder.next;
        }
        
        _reservedAmount -= total;
        payable(_msgSender()).sendValue(total-(total/11));
        return (total-(total/11),amount - remainingAmount);
    }
    
    function _buyAmount(uint256 amount, uint256 maxPrice, uint256 availableValue) private returns(uint256,uint256){
        require(amount > 0);
        require(maxPrice > 0);
        uint256 remainingAmount = amount + amount / 10;
        uint256 remainingValue = availableValue;
        uint256 current = firstSellId;
        while(current !=0 && remainingAmount > 0){
            Order storage currentOrder = orders[current];
            if(currentOrder.owner != _msgSender()){
                if(currentOrder.price > maxPrice){
                    break;
                }
                uint256 payableAmount = remainingValue / currentOrder.price;
                payableAmount =  payableAmount < remainingAmount ? payableAmount : remainingAmount;
                if(payableAmount == 0){
                    break;
                }
                if(currentOrder.amount < payableAmount){
                    remainingValue -= currentOrder.amount * currentOrder.price;
                    remainingAmount -= currentOrder.amount;
                    payable(currentOrder.owner).sendValue(currentOrder.amount * currentOrder.price);
                    _removeOrder(current);
                }
                else {
                    remainingAmount -= payableAmount;
                    remainingValue -= payableAmount * currentOrder.price;
                    currentOrder.amount -= payableAmount;
                    payable(currentOrder.owner).sendValue(payableAmount * currentOrder.price);
                }
            }
            current = currentOrder.next;
        }
        
        uint256 total = amount + amount / 10 - remainingAmount;
        
        _reservedTokenAmount -= total;
        _transfer(address(this), _msgSender(), total-(total/11));
        return (total-(total/11), availableValue - remainingValue);
        
    }
    
}