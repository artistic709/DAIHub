pragma solidity ^0.5.15;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Mintable.sol";
import "./interface/Proxy.sol";
import "./interface/Borrower.sol";

contract DAIHub is ERC20Mintable, Ownable {
    using SafeMath for uint256;

    event ProposeProxy(address proxy, uint256 mature);
    event AddProxy(address proxy);
    event Borrow(address indexed who, uint256 amount);
    
    mapping(address => bool) public isProxy;
    address[] public proxies;
    address public pendingProxy;
    uint256 public mature;
    uint256 public repayRate = 1.003e18; // amount to repay = borrow * repayRate / 1e18
    
    ERC20 DAI = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    //ERC20 token info
    uint8 public decimals = 18;
    string public name = "DAIHub";
    string public symbol = "hDAI";

    //constructor
    constructor(address[] memory _proxies, address _dai) public {
        DAI = ERC20(_dai);
        for (uint256 i = 0; i < _proxies.length; i++) {
            proxies.push(_proxies[i]);
            isProxy[_proxies[i]] = true;
            DAI.approve(_proxies[i], uint256(-1));
        }
    }

    function exchangeRate() public view returns (uint256 rate) {
        rate = totalValueStored().div(totalSupply());
    }

    function totalValueStored() public view returns (uint256 sum) {
        sum = cash();
        for (uint256 i = 0; i < proxies.length; i++) {
            sum = sum.add(Proxy(proxies[i]).totalValueStored());
        }
    }

    //calculate value from all proxies and cash
    function totalValue() public returns (uint256 sum) {
        sum = cash();
        for (uint256 i = 0; i < proxies.length; i++) {
            sum = sum.add(Proxy(proxies[i]).totalValue());
        }
    }

    //cash value of an user"s deposit
    function balanceOfUnderlying(address who) public returns (uint256) {
        return balanceOf(who).mul(totalValue()).div(totalSupply());
    }

    // cash in this contract
    function cash() public view returns (uint256) {
        return DAI.balanceOf(address(this));
    }

    // deposit money to this contract
    function deposit(address to, uint256 amount)
        external
        returns (uint256 increased)
    {
        if (totalSupply() > 0) {
            increased = totalSupply().mul(amount).div(totalValue());
            _mint(to, increased);
        } else {
            increased = amount;
            _mint(to, amount);
        }

        require(DAI.transferFrom(msg.sender, address(this), amount));
    }

    //withdraw money by burning `amount` share
    function withdraw(address to, uint256 amount) external {
        uint256 withdrawal = amount.mul(totalValue()).div(totalSupply());
        _burn(msg.sender, amount);
        _withdraw(to, withdrawal);
    }

    //withdraw certain `amount` of money
    function withdrawUnderlying(address to, uint256 amount) external {
        uint256 shareToBurn = amount.mul(totalSupply()).div(totalValue()).add(
            1
        );
        _burn(msg.sender, shareToBurn);
        _withdraw(to, amount);
    }

    //borrow `amount` token, call by EOA
    function borrow(address to, uint256 amount, bytes calldata data) external {
        uint256 repayAmount = amount.mul(repayRate).div(1e18);
        _withdraw(to, amount);
        Borrower(to).receiveToken(
            msg.sender,
            address(DAI),
            amount,
            repayAmount,
            data
        );
        require(DAI.transferFrom(to, address(this), repayAmount));
    }

    //borrow `amount` token, call by contract
    function borrow(uint256 amount) external {
        uint256 repayAmount = amount.mul(repayRate).div(1e18);
        _withdraw(msg.sender, amount);
        Borrower(msg.sender).receiveToken(
            msg.sender,
            address(DAI),
            amount,
            repayAmount,
            bytes("")
        );
        require(DAI.transferFrom(msg.sender, address(this), repayAmount));
    }

    function _withdraw(address to, uint256 amount) internal {
        uint256 _cash = cash();

        if (amount <= _cash) {
            require(DAI.transfer(msg.sender, amount));
        } else {
            require(DAI.transfer(msg.sender, _cash));
            amount -= _cash;

            for (uint256 i = 0; i < proxies.length && amount > 0; i++) {
                _cash = Proxy(proxies[i]).totalValue();
                if (_cash == 0) continue;
                if (amount <= _cash) {
                    Proxy(proxies[i]).withdraw(to, amount);
                    amount = 0;
                } else {
                    Proxy(proxies[i]).withdraw(to, _cash);
                    amount -= _cash;
                }
            }
            require(amount == 0);
        }
    }

    //propose a new proxy to be added
    function proposeProxy(address _proxy) external onlyOwner {
        pendingProxy = _proxy;
        mature = now.add(7 days);
        emit ProposeProxy(_proxy, mature);
    }

    //add a new proxy by owner
    function addProxy() external onlyOwner {
        require(now >= mature);
        require(isProxy[pendingProxy] == false);
        //require(Proxy(pendingProxy).isProxy());
        isProxy[pendingProxy] = true;
        proxies.push(pendingProxy);
        DAI.approve(pendingProxy, uint256(-1));
        emit AddProxy(pendingProxy);
        pendingProxy = address(0);
    }

    //invest cash to a proxy
    function invest(address _proxy, uint256 amount) external onlyOwner {
        require(isProxy[_proxy], "Unexpected Proxy");
        Proxy(_proxy).deposit(amount);
    }

    //redeem investment from a proxy
    function redeem(address _proxy, uint256 amount) external onlyOwner {
        require(isProxy[_proxy]);
        Proxy(_proxy).withdraw(address(this), amount);
    }

    //set new repay rate
    function setRepayRate(uint256 newRepayRate) external onlyOwner {
        require(newRepayRate <= 1.05e18); //repayRate must be less than 105%
        repayRate = newRepayRate;
    }

    //swap position of two proxies in list
    function swapProxy(uint256 a, uint256 b) external onlyOwner {
        require(a < proxies.length && b < proxies.length);
        (proxies[a], proxies[b]) = (proxies[b], proxies[a]);
    }

}
