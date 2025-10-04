// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

interface ILPToken {
    function totalSupply() external view returns (uint256);
}

contract RugwatchTrap is ITrap {
    // collect() must have zero args (Drosera passes config_data appended to calldata)
    // config_data format: abi.encode(address pool, uint256 threshold)
    // threshold is an absolute drop in totalSupply (units of token supply)
    // collect returns abi.encode(pool, currentTotalSupply, threshold)

    function collect() external view override returns (bytes memory) {
        // require at least selector (4) + 32 + 32 bytes for (address,uint256)
        if (msg.data.length < 4 + 32 + 32) {
            // not enough config data provided — return zeros (non-reverting)
            return abi.encode(address(0), uint256(0), uint256(0));
        }

        (address pool, uint256 threshold) = abi.decode(msg.data[4:], (address, uint256));

        uint256 supply = 0;
        // call the LP token's totalSupply safely
        try ILPToken(pool).totalSupply() returns (uint256 ts) {
            supply = ts;
        } catch {
            // read failed, return pool with supply 0
            return abi.encode(pool, uint256(0), threshold);
        }

        return abi.encode(pool, supply, threshold);
    }

    // data[] elements are the bytes returned by collect() for sampled blocks
    // We expect at least two samples and compare the previous and recent totalSupply
    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length < 2) return (false, "");

        // decode last two samples
        (address poolPrev, uint256 prevSupply, uint256 thresholdPrev) = abi.decode(data[data.length - 2], (address, uint256, uint256));
        (address poolRecent, uint256 recentSupply, uint256 thresholdRecent) = abi.decode(data[data.length - 1], (address, uint256, uint256));

        // basic sanity: pools must match and threshold must match; otherwise do not fire
        if (poolPrev == address(0) || poolRecent == address(0)) return (false, "");
        if (poolPrev != poolRecent) return (false, "");

        // use threshold from recent (they should match)
        uint256 threshold = thresholdRecent;

        // if supply dropped by at least threshold, fire
        if (prevSupply > recentSupply) {
            uint256 diff = prevSupply - recentSupply;
            if (diff >= threshold) {
                // pack (pool, prevSupply, recentSupply, diff) as response args
                return (true, abi.encode(poolPrev, prevSupply, recentSupply, diff));
            }
        }

        return (false, "");
    }
}
