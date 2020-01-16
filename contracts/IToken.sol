pragma solidity ^0.5.15;

import "./interface/IERC20.sol";

contract IToken is IERC20 {
    function mint(address receiver, uint256 depositAmount)
        external
        returns (uint256 mintAmount);
    function burn(address receiver, uint256 burnAmount)
        external
        returns (uint256 loanAmountPaid);
    function tokenPrice() external view returns (uint256 price);
    function assetBalanceOf(address _owner) external view returns (uint256);
}
