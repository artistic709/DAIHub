pragma solidity ^0.5.15;

import '../DAIHub.sol';

contract TestDAIHub is DAIHub {
    constructor(address[] memory _proxies, address _dai) public DAIHub(_proxies, _dai) {}
}
