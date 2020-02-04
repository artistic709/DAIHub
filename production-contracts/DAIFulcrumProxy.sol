pragma solidity ^0.5.16;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) 
            return 0;
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 internal _totalSupply;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return A uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token to a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender"s allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */
    function approve(address spender, uint256 value) public returns (bool) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another.
    * Note that while this function emits an Approval event, this is not required as per the specification,
    * and other compliant implementations may not emit the event.
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _allowed[msg.sender][to] = _allowed[msg.sender][to].sub(value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

}

contract IERC20 is ERC20 {
    function mint(address receiver, uint256 depositAmount) external returns (uint256 mintAmount);
    function burn(address receiver, uint256 burnAmount) external returns (uint256 loanAmountPaid);
    function tokenPrice() external view returns (uint256 price);
    function assetBalanceOf(address _owner) external view returns (uint256);
}

contract DAIFulcrumProxy is Ownable {
    using SafeMath for uint256;

    IERC20 constant IDAI = IERC20(0x493C57C4763932315A328269E1ADaD09653B9081);
    ERC20 constant DAI = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    address constant hub = address(0xf6377c5B47410BDce0086864067787367D07A1c7);
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

    function isProxy() external pure returns(bool) {
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

    function totalValue() public returns(uint256) {
        return updateTotalValue();
    }

    function updateTotalValue() internal returns(uint256) {
        uint256 newBalance = IDAI.assetBalanceOf(address(this));
        uint256 reserveAdded = newBalance.sub(totalValueStored).sub(reserve).mul(reserveRate).div(1e18);
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
