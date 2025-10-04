// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Script.sol";
import "../src/RugwatchResponse.sol";

contract DeployResponse is Script {
    function run() external {
        uint256 key = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(key);

        RugwatchResponse resp = new RugwatchResponse();

        vm.stopBroadcast();
        console2.log("RugwatchResponse deployed at:", address(resp));
    }
}

