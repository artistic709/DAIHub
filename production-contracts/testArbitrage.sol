pragma solidity ^0.5.16;

contract borrowTokenFallBack {
    function receiveToken(address caller, address token, uint256 amount, uint256 amountToRepay, bytes calldata data) external returns(bytes4);
}

contract DAIHub {
    function borrow(uint256 amount) external;
    function borrow(address to, uint256 amount, bytes calldata data) external;
}

contract Erc20 {
    function balanceOf(address owner) view public returns(uint256);
    function transfer(address to, uint256 amount) public returns(bool);
    function approve(address spender, uint256 amount) public returns(bool);
}

contract testArbitrage is borrowTokenFallBack {
    bytes4 constant BORROW_TOKEN_ACCEPTED = 0x58ca01a1; //bytes4(keccak256("receiveToken(address,address,uint256,uint256,bytes)"))
    Erc20 dai = Erc20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    DAIHub daihub = DAIHub(0xf6377c5B47410BDce0086864067787367D07A1c7);

    constructor() public {
        dai.approve(address(daihub), uint256(-1));
    }

    function receiveToken(address, address, uint256 amount, uint256, bytes calldata) external returns(bytes4) {
        return BORROW_TOKEN_ACCEPTED;
    }

    function test(uint256 amount) public {
        daihub.borrow(amount);
    }

    function withdraw() external {
        DAI.transfer(msg.sender, DAI.balanceOf(address(this)));
    }
}
