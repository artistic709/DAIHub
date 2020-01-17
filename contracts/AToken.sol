pragma solidity ^0.5.15;

import "./interface/IERC20.sol";

contract AToken is IERC20 {
  function redeem(uint256 _amount) external;
}