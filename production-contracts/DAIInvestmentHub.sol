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

contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
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
        if(_allowed[msg.sender][to] < uint256(-1)) {
            _allowed[msg.sender][to] = _allowed[msg.sender][to].sub(value);
        }
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

}

contract ERC20Mintable is ERC20 {

    function _mint(address to, uint256 amount) internal {
        _balances[to] = _balances[to].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        _balances[from] = _balances[from].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(from, address(0), amount);
    }

}

contract borrowTokenFallBack {
    function receiveToken(address caller, address token, uint256 amount, uint256 amountToRepay, bytes calldata data) external returns(bytes4);
}

contract proxy {
    function totalValue() external returns(uint256);
    function totalValueStored() external view returns(uint256);
    function deposit(uint256 amount) external;
    function withdraw(address to, uint256 amount) external;
    function isProxy() external returns(bool);
}

contract DAIInvestmentHub is ERC20Mintable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public repayRate; // amount to repay = borrow * repayRate / 1e18
    uint256 public constant withdrawPeriod = 7 days;
    uint256 public lastTimeStamp;
    uint256 public globalIndex;

    address public defaultProxy;

    bytes4 constant BORROW_TOKEN_ACCEPTED = 0x58ca01a1; //bytes4(keccak256("receiveToken(address,address,uint256,uint256,bytes)"))

    ERC20 constant DAI = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    mapping(address => uint256) public pendingWithdrawal;
    mapping(address => uint256) public localIndex;
    mapping(address => uint256) public redeemable;

    mapping(address => uint256) public pendingProxyMature; 
    mapping(address => bool) public isProxy;

    address[] public proxies;

    event ProposeProxy(address proxy, uint256 mature);
    event AddProxy(address proxy);
    event Borrow(address indexed who, uint256 amount);

    //calculate value from all proxies and cash
    function totalValue() public returns(uint256 sum) {  
        sum = cash();
        for(uint256 i = 0; i < proxies.length; i++){
            sum = sum.add(proxy(proxies[i]).totalValue());
        }
    }

    function totalValueStored() public view returns(uint256 sum) {
        sum = cash();
        for(uint256 i = 0; i < proxies.length; i++){
            sum = sum.add(proxy(proxies[i]).totalValueStored());
        }
    }

    //cash value of an user's deposit
    function balanceOfUnderlying(address who) external returns(uint256 amount) {
        return balanceOf(who).mul(totalValue()).div(totalSupply());
    }

    function balanceOfUnderlyingStored(address who) external view returns(uint256 amount) {
        return balanceOf(who).mul(totalValueStored()).div(totalSupply());
    }

    // cash in this contract
    function cash() public view returns(uint256) {
        return DAI.balanceOf(address(this));
    }

    // deposit money to this contract
    function deposit(address to, uint256 amount) external nonReentrant returns(uint256 increased) {
        if(totalSupply() > 0) {
            increased = totalSupply().mul(amount).div(totalValue());
            _mint(to, increased);
        }
        else {
            increased = amount;
            _mint(to, amount);
        }

        require(DAI.transferFrom(msg.sender, address(this), amount));

        if(defaultProxy != address(0))
            proxy(defaultProxy).deposit(amount);
    }

    //withdraw money by burning `amount` share
    function withdraw(address to, uint256 amount) external nonReentrant {
        uint256 withdrawal = amount.mul(totalValue()).div(totalSupply());
        _burn(msg.sender, amount);
        addPendingWithdrawal(to, withdrawal);
    }

    //withdraw certain `amount` of money
    function withdrawUnderlying(address to, uint256 amount) external nonReentrant {
        uint256 shareToBurn = amount.mul(totalSupply()).div(totalValue()).add(1);
        _burn(msg.sender, shareToBurn);
        addPendingWithdrawal(to, amount);
    }

    function updateGlobalIndex() internal {
        uint256 timeWentBy = now.sub(lastTimeStamp);
        globalIndex = globalIndex.add(timeWentBy.mul(1e18).div(withdrawPeriod));
        lastTimeStamp = now;
    }

    function updateLocalIndex(address user) internal {
        uint256 diff = globalIndex.sub(localIndex[user]);
        if(diff > 1e18) diff = 1e18;
        redeemable[user] = redeemable[user].add(pendingWithdrawal[user].mul(diff).div(1e18));
        localIndex[user] = globalIndex;
    }

    function addPendingWithdrawal(address to, uint256 amount) internal {
        updateGlobalIndex();
        updateLocalIndex(to);
        pendingWithdrawal[to] = pendingWithdrawal[to].add(amount);
    }

    function claim(address to, uint256 amount) external nonReentrant {
        updateGlobalIndex();
        updateLocalIndex(to);
        redeemable[msg.sender] = redeemable[msg.sender].sub(amount);
        pendingWithdrawal[msg.sender] = pendingWithdrawal[msg.sender].sub(amount);
        _withdraw(to, amount);
    }

    //borrow `amount` token, call by EOA
    function borrow(address to, uint256 amount, bytes calldata data) external nonReentrant {
        uint256 repayAmount = amount.mul(repayRate).div(1e18);
        _borrow(to, amount);
        require(borrowTokenFallBack(to).receiveToken(msg.sender, address(DAI), amount, repayAmount, data) == BORROW_TOKEN_ACCEPTED);
        require(DAI.transferFrom(to, address(this), repayAmount));
        emit Borrow(to, amount);
    }

    //borrow `amount` token, call by contract
    function borrow(uint256 amount) external nonReentrant {
        uint256 repayAmount = amount.mul(repayRate).div(1e18);
        _borrow(msg.sender, amount);
        require(borrowTokenFallBack(msg.sender).receiveToken(msg.sender, address(DAI), amount, repayAmount, bytes("")) == BORROW_TOKEN_ACCEPTED);
        require(DAI.transferFrom(msg.sender, address(this), repayAmount));
        emit Borrow(msg.sender, amount);
    }

    function _borrow(address to, uint256 amount) internal {
        uint256 _cash = cash();

        if(amount <= _cash) {
            require(DAI.transfer(msg.sender, amount));
        }
        else {
            require(DAI.transfer(msg.sender, _cash));
            amount -= _cash;
            proxy(defaultProxy).withdraw(to, amount);
        }
    }   

    function _withdraw(address to, uint256 amount) internal {
        uint256 _cash = cash();

        if(amount <= _cash) {
            require(DAI.transfer(msg.sender, amount));
        }
        else {
            require(DAI.transfer(msg.sender, _cash));
            amount -= _cash;
            
            for(uint256 i = 0; i < proxies.length && amount > 0; i++) {
                _cash = proxy(proxies[i]).totalValue();
                if(_cash == 0) continue;
                if(amount <= _cash) {
                    proxy(proxies[i]).withdraw(to, amount);
                    amount = 0;
                }
                else {
                    proxy(proxies[i]).withdraw(to, _cash);
                    amount -= _cash;
                }
            }
            require(amount == 0);
        }
    }

    //propose a new proxy to be added
    function proposeProxy(address _proxy) external onlyOwner {
        pendingProxyMature[_proxy] = now.add(withdrawPeriod);
        emit ProposeProxy(_proxy, pendingProxyMature[_proxy]);
    }

    //add a new proxy by owner
    function addProxy(address _proxy) external onlyOwner {
        require(pendingProxyMature[_proxy] > 0);
        require(now >= pendingProxyMature[_proxy]);
        require(isProxy[_proxy] == false);
        //require(proxy(pendingProxy).isProxy());
        isProxy[_proxy] = true;
        proxies.push(_proxy);
        DAI.approve(_proxy, uint256(-1));
        emit AddProxy(_proxy);
    }

    //invest cash to a proxy
    function invest(address _proxy, uint256 amount) external onlyOwner {
        require(isProxy[_proxy]);
        proxy(_proxy).deposit(amount);
    }

    //redeem investment from a proxy
    function redeem(address _proxy, uint256 amount) external onlyOwner {
        require(isProxy[_proxy]);
        proxy(_proxy).withdraw(address(this), amount);
    }

    //set new repay rate
    function setRepayRate(uint256 newRepayRate) external onlyOwner {
        require(newRepayRate >= 1e18 && newRepayRate <= 1.05e18); //repayRate must be between 100% and 105%
        repayRate = newRepayRate;
    }

    function setDefaultProxy(address  _proxy) external onlyOwner {
        require(isProxy[_proxy] || _proxy == address(0));
        defaultProxy = _proxy;
    }

    //swap position of two proxies in list
    function swapProxy(uint256 a, uint256 b) external onlyOwner {
        require(a < proxies.length && b < proxies.length);
        (proxies[a], proxies[b]) = (proxies[b], proxies[a]);
    }

    //ERC20 token info
    uint8 public decimals;
    string public name;
    string public symbol; 

    //constructor
    constructor(address[] memory _proxies) public {
        for(uint256 i = 0; i < _proxies.length; i++){
            proxies.push(_proxies[i]);
            isProxy[_proxies[i]] = true;
            DAI.approve(_proxies[i], uint256(-1));
        }
        repayRate = 1.002e18;
        decimals = 18;
        name = "DAIHub";
        symbol = "hDAI";
        lastTimeStamp = now;
    }
}
