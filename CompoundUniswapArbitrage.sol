pragma solidity ^0.5.12;

contract Erc20 {
    function balanceOf(address owner) view public returns(uint256);
    function transfer(address to, uint256 amount) public returns(bool);
    function approve(address spender, uint256 amount) public returns(bool);
}

contract CErc20 is Erc20 {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
}

contract Exchange {
    function tokenToExchangeSwapInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_eth_bought, 
    uint256 deadline, 
    address exchange_addr) 
    public returns (uint256);
}

contract borrowTokenFallBack {
    function receiveToken(address caller, address token, uint256 amount, uint256 amountToRepay, bytes calldata data) external;
}

contract DAIHub {
    function borrow(address to, uint256 amount, bytes calldata data) external;
}

contract arbitrage1 is borrowTokenFallBack {
    
    Exchange UniCDai = Exchange(0x34E89740adF97C3A9D3f63Cc2cE4a914382c230b);
    Exchange UniDai = Exchange(0x2a1530C4C41db0B0b2bB646CB5Eb1A67b7158667);

    Erc20 dai = Erc20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    CErc20 cDai = CErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);

    DAIHub daihub = DAIHub(0xbeef);

    constructor() public {
        dai.approve(address(UniDai), uint256(-1));
    }

    // dai -> uniswap -> cdai -> redeem -> dai
    function receiveToken(address, address, uint256 amount, uint256, bytes calldata) external {
        uint256 tokenAmount = UniDai.tokenToExchangeSwapInput((amount), 1, 1, now, address(UniCDai));
        cDai.redeem(tokenAmount);
    }

    function play(uint256 amount) public returns(uint256) {
        daihub.borrow(address(this), amount, bytes(""));
        uint256 earning = dai.balanceOf(address(this));
        dai.transfer(msg.sender, earning);
        return earning;
    }

}

contract arbitrage2 is borrowTokenFallBack {
    
    Exchange UniCDai = Exchange(0x34E89740adF97C3A9D3f63Cc2cE4a914382c230b);
    Exchange UniDai = Exchange(0x2a1530C4C41db0B0b2bB646CB5Eb1A67b7158667);

    Erc20 dai = Erc20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    CErc20 cDai = CErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);

    DAIHub daihub = DAIHub(0xbeef);

    constructor() public {
        cDai.approve(address(UniCDai),uint256(-1));
        dai.approve(address(cDai), uint256(-1));
    }

    function receiveToken(address, address, uint256 amount, uint256, bytes calldata) external {
        cDai.mint(amount);
        uint256 ctokenAmount = cDai.balanceOf(address(this));
        UniCDai.tokenToExchangeSwapInput(ctokenAmount, 1,  1,  now, address(UniDai));
    }

    function play(uint256 amount) public returns(uint256) {
        daihub.borrow(address(this), amount, bytes(""));
        uint256 earning = dai.balanceOf(address(this));
        dai.transfer(msg.sender, earning);
        return earning;
    }

}