// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../IERC20.sol";
import "../../../access/AccessControl.sol";
import "../../../utils/introspection/ERC165.sol";

interface IERC20WithAccessControl is IERC165, IERC20{
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function transfer(address from, address to, uint256 amount) external;
}

contract ERC20WithAccessControl is IERC20WithAccessControl, ERC20, AccessControl {
    
    bytes32 public constant mintRole =  keccak256("ERC20WithAccessControl/mint");
    bytes32 public constant burnRole =  keccak256("ERC20WithAccessControl/burn");
    bytes32 public constant transferRole =  keccak256("ERC20WithAccessControl/transfer");
    
    constructor (string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
    
    function mint(address account, uint256 amount) external override onlyRole(mintRole){
        _mint(account, amount);
    }
    
    function burn(address account, uint256 amount) external override onlyRole(burnRole){
        _burn(account, amount);
    }
    
    function decimals() public pure override returns(uint8) {
        return 0;
    }
    
    function transfer(address from, address to, uint256 amount) external override onlyRole(transferRole){
        _transfer(from, to, amount);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, IERC165) returns (bool) {
        return interfaceId == type(IERC20WithAccessControl).interfaceId
            || AccessControl.supportsInterface(interfaceId);
    }
}