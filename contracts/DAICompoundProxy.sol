pragma solidity ^0.5.15;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./CToken.sol";

contract DAICompoundProxy is Ownable {
    using SafeMath for uint256;

    CToken constant CDAI = CToken(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
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
        DAI.approve(address(CDAI), uint256(-1));
        wallet = _wallet;
        reserveRate = _reserveRate;
    }

    function isProxy() external pure returns (bool) {
        return true;
    }

    function deposit(uint256 amount) external onlyHub {
        totalValueStored = updateTotalValue().add(amount);
        require(DAI.transferFrom(hub, address(this), amount));
        require(CDAI.mint(amount) == 0);
    }

    function withdraw(address to, uint256 amount) external onlyHub {
        totalValueStored = updateTotalValue().sub(amount);
        require(CDAI.redeemUnderlying(amount) == 0);
        require(DAI.transfer(to, amount));
    }

    function totalValue() public returns (uint256) {
        return updateTotalValue();
    }

    function updateTotalValue() internal returns (uint256) {
        if (CDAI.balanceOf(address(this)) <= 10) return 0;
        uint256 newBalance = CDAI.balanceOfUnderlying(address(this));
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
        require(CDAI.redeemUnderlying(amount) == 0);
        require(DAI.transfer(wallet, amount));
    }

}
