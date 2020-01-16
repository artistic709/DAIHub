pragma solidity ^0.5.15;

import "./interface/Borrower.sol";
import "./ERC20.sol";
import "./CToken.sol";
import "./Uniswap.sol";
import "./DAIHub.sol";

contract arbitrage1 is Borrower {
    Uniswap UniCDai = Uniswap(0x34E89740adF97C3A9D3f63Cc2cE4a914382c230b);
    Uniswap UniDai = Uniswap(0x2a1530C4C41db0B0b2bB646CB5Eb1A67b7158667);

    ERC20 dai = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    CToken cDai = CToken(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);

    DAIHub daihub = DAIHub(0xbeef);

    constructor() public {
        dai.approve(address(UniDai), uint256(-1));
    }

    // dai -> uniswap -> cdai -> redeem -> dai
    function receiveToken(
        address,
        address,
        uint256 amount,
        uint256,
        bytes calldata
    ) external {
        uint256 tokenAmount = UniDai.tokenToExchangeSwapInput(
            (amount),
            1,
            1,
            now,
            address(UniCDai)
        );
        cDai.redeem(tokenAmount);
    }

    function play(uint256 amount) public returns (uint256) {
        daihub.borrow(address(this), amount, bytes(""));
        uint256 earning = dai.balanceOf(address(this));
        dai.transfer(msg.sender, earning);
        return earning;
    }

}
