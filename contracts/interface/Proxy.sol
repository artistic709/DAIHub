pragma solidity ^0.5.15;

interface Proxy {
    function totalValue() external returns (uint256);
    function totalValueStored() external view returns (uint256);
    function deposit(uint256 amount) external returns (bool);
    function withdraw(address to, uint256 amount) external returns (bool);
    function isProxy() external returns (bool);
}
