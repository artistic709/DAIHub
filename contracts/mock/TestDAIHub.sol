pragma solidity ^0.5.15;

import '../DAIHub.sol';

contract TestDAIHub is DAIHub {
  function setDAI(address _dai) external {
    DAI = ERC20(_dai);
  }
}
