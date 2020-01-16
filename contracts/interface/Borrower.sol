pragma solidity ^0.5.15;

interface Borrower {
    function receiveToken(
        address caller,
        address token,
        uint256 amount,
        uint256 amountToRepay,
        bytes calldata data
    ) external;
}
