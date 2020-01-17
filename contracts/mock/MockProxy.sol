pragma solidity 0.5.15;

import "../SafeMath.sol";
import "../interface/Proxy.sol";
import "../ERC20.sol";

contract MockProxy is Proxy {
    using SafeMath for uint256;

    uint256 internal _totalValue;
    uint256 internal _totalValueStored;
    ERC20 public DAI;
    address public hub;

    constructor(address _dai) public {
      DAI = ERC20(_dai);
    }

    function setHub(address _hub) external {
      hub = _hub;
    }

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
      DAI.transferFrom(hub, address(this), amount);
      return true;
    }

    function withdraw(address to, uint256 amount) external returns (bool) {
      require(to != address(0) && amount >= 0);
      _totalValue = _totalValue.sub(amount);
      _totalValueStored = _totalValueStored.sub(amount);
      DAI.transfer(hub, amount);
      return true;
    }

    function isProxy() external returns (bool) {
      return true;
    }
    
}