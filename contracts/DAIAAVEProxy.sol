pragma solidity ^0.5.15;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./AToken.sol";
import "./AAVE.sol";

contract DAIAAVEProxy is Ownable {
    using SafeMath for uint256;

    AToken constant ADAI = AToken(0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d);
    AAVE constant aave = AAVE(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);
    ERC20 constant DAI = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    address constant hub = address(0xbeef);
    address internal wallet;

    uint256 public totalValueStored;
    uint256 public reserve;
    uint256 public reserveRate;
    uint16 internal referralCode;
    
    modifier onlyHub() {
        require(msg.sender == hub);
        _;
    }

    constructor(address _wallet, uint256 _reserveRate) public {
        DAI.approve(address(aave), uint256(-1));
        wallet = _wallet;
        reserveRate = _reserveRate;
    }

    function isProxy() external pure returns(bool) {
        return true;
    }

    function deposit(uint256 amount) external onlyHub {
        totalValueStored = updateTotalValue().add(amount);
        require(DAI.transferFrom(hub, address(this), amount));
        aave.deposit(address(DAI), amount, referralCode);
    }

    function withdraw(address to, uint256 amount) external onlyHub {
        totalValueStored = updateTotalValue().sub(amount);
        ADAI.redeem(amount);
        require(DAI.transfer(to, amount));
    }

    function totalValue() public returns(uint256) {
        return updateTotalValue();
    }

    function updateTotalValue() internal returns(uint256) {
        uint256 newBalance = ADAI.balanceOf(address(this));
        uint256 reserveAdded = newBalance.sub(totalValueStored).mul(reserveRate).div(1e18);
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
        ADAI.redeem(amount);
        require(DAI.transfer(wallet, amount));
    }

}