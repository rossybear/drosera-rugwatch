// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract RugwatchResponse {
    event RugDetected(address indexed pool, uint256 prevSupply, uint256 newSupply, uint256 withdrawn);
    mapping(address => uint256) public lastTriggeredBlock;

    function handleRug(address pool, uint256 prevSupply, uint256 newSupply, uint256 withdrawn) external {
        require(withdrawn > 0, "no-withdrawal");
        lastTriggeredBlock[pool] = block.number;
        emit RugDetected(pool, prevSupply, newSupply, withdrawn);
    }
}
