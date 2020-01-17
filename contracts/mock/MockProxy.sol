pragma solidity 0.5.15;

import '../SafeMath.sol';
import '../interface/Proxy.sol';

contract MockProxy is Proxy {
    using SafeMath for uint256;

    uint256 internal _totalValue;
    uint256 internal _totalValueStored;

    function totalValue() external returns (uint256) {
      return _totalValue;
    }

    function setTotalValue(uint256 value) external {
      _totalValue = value;
    }

    function totalValueStored() external view returns (uint256) {
      return _totalValueStored;
    }

    function setTotalValueStored(uint256 value) external {
      _totalValueStored = value;
    }

    function deposit(uint256 amount) external returns (bool) {
      require(amount >= 0);
      _totalValue = _totalValue.add(amount);
      _totalValueStored = _totalValueStored.add(amount);
      return true;
    }

    function withdraw(address to, uint256 amount) external returns (bool) {
      require(to != address(0) && amount >= 0);
      _totalValue = _totalValue.sub(amount);
      _totalValueStored = _totalValueStored.sub(amount);
      return true;
    }

    function isProxy() external returns (bool) {
      return true;
    }
    
}