// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test{
    function idToPositon(uint256 id) public pure returns(int128, int128){
        return (int128(uint128(id >> 128)), int128(uint128(id)));
    }
    
    function positionToId(int128 x, int128 y) public pure returns(uint256){
        return (uint256(uint128(x)) << 128) + uint256(uint128(y)); 
    }
    
    function intToUint(int128 i) public pure returns(uint256){
        return uint256(uint128(i));
    }
    
    function uintToInt(uint256 u) public pure returns(int128){
        return int128(uint128(u));
    }
    
    function decal(uint256 u, uint256 d) public pure returns(uint256){
        return u << d;
    }
    
    function decalr(uint256 u, uint256 d) public pure returns(uint256){
        return u >> d;
    }
    
    function sum(uint256 a, uint256 b) public pure returns(uint256){
        return a + b;
    }
}