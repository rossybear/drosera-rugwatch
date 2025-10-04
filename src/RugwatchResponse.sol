// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract RugwatchResponse {
    // Minimal response: emit event and optionally set a cooldown flag
    event RugDetected(address indexed pool, uint256 prevSupply, uint256 newSupply, uint256 withdrawn);
    // small mapping so response can block repeated responses for same pool (optional basic cooldown)
    mapping(address => uint256) public lastTriggeredBlock;

    // caller is the Drosera operator (no access control here to keep it simple)
    function handleRug(address pool, uint256 prevSupply, uint256 newSupply, uint256 withdrawn) external {
        require(withdrawn > 0, "no-withdrawal");
        // set last triggered block to current block
        lastTriggeredBlock[pool] = block.number;
        emit RugDetected(pool, prevSupply, newSupply, withdrawn);

        // Additional defensive actions (pauses, integrations) are up to you — keep minimal for safety
    }
}
