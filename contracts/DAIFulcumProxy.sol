pragma solidity ^0.5.15;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./IToken.sol";

contract DAIFulcrumProxy is Ownable {
    using SafeMath for uint256;

    IToken constant IDAI = IToken(0x493C57C4763932315A328269E1ADaD09653B9081);
    ERC20 constant DAI = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    address constant hub = address(0xbeef);
    address internal wallet;

    uint256 public totalValueStored;
    uint256 public reserve;
    uint256 public reserveRate;

    modifier onlyHub() {
        require(msg.sender == hub);
        _;
    }

    constructor(address _wallet, uint256 _reserveRate) public {
        DAI.approve(address(IDAI), uint256(-1));
        wallet = _wallet;
        reserveRate = _reserveRate;
    }

    function isProxy() external pure returns (bool) {
        return true;
    }

    function deposit(uint256 amount) external onlyHub {
        totalValueStored = updateTotalValue().add(amount);
        require(DAI.transferFrom(hub, address(this), amount));
        require(IDAI.mint(address(this), DAI.balanceOf(address(this))) > 0);
    }

    function withdraw(address to, uint256 amount) external onlyHub {
        totalValueStored = updateTotalValue().sub(amount);

        uint256 burnAmount = amount.mul(1e18).div(IDAI.tokenPrice());
        require(IDAI.burn(address(this), burnAmount.add(1)) > 0);
        require(DAI.transfer(to, amount));
    }

    function totalValue() public returns (uint256) {
        return updateTotalValue();
    }

    function updateTotalValue() internal returns (uint256) {
        uint256 newBalance = IDAI.assetBalanceOf(address(this));
        uint256 reserveAdded = newBalance
            .sub(totalValueStored)
            .mul(reserveRate)
            .div(1e18);
        reserve = reserve.add(reserveAdded);
        totalValueStored = newBalance.sub(reserve);
        return totalValueStored;
    }

    function setWallet(address _wallet) external onlyOwner {
        wallet = _wallet;
    }

    function setReserveRate(uint256 _reserveRate) external onlyOwner {
        require(_reserveRate <= 2e17);
        reserveRate = _reserveRate;
    }

    function claimReserve(uint256 amount) external onlyOwner {
        updateTotalValue();
        reserve = reserve.sub(amount);
        uint256 burnAmount = amount.mul(1e18).div(IDAI.tokenPrice());
        require(IDAI.burn(address(this), burnAmount.add(1)) > 0);
        require(DAI.transfer(wallet, amount));
    }

}
