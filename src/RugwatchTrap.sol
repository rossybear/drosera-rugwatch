// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ITrap} from "./interfaces/ITrap.sol";

interface ILPToken {
    function totalSupply() external view returns (uint256);
}

contract RugwatchTrap is ITrap {
    // collect() reads totalSupply and encodes pool, supply, threshold
    function collect() external view override returns (bytes memory) {
        if (msg.data.length < 4 + 32 + 32) {
            return abi.encode(address(0), uint256(0), uint256(0));
        }

        (address pool, uint256 threshold) = abi.decode(msg.data[4:], (address, uint256));

        uint256 supply = 0;
        try ILPToken(pool).totalSupply() returns (uint256 ts) {
            supply = ts;
        } catch {
            return abi.encode(pool, uint256(0), threshold);
        }

        return abi.encode(pool, supply, threshold);
    }

    // shouldRespond compares the last two samples to decide if rug pull occurred
    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length < 2) return (false, "");

        (address poolPrev, uint256 prevSupply, uint256 thresholdPrev) =
            abi.decode(data[data.length - 2], (address, uint256, uint256));
        (address poolRecent, uint256 recentSupply, uint256 thresholdRecent) =
            abi.decode(data[data.length - 1], (address, uint256, uint256));

        if (poolPrev == address(0) || poolRecent == address(0)) return (false, "");
        if (poolPrev != poolRecent) return (false, "");

        uint256 threshold = thresholdRecent;

        if (prevSupply > recentSupply) {
            uint256 diff = prevSupply - recentSupply;
            if (diff >= threshold) {
                return (true, abi.encode(poolPrev, prevSupply, recentSupply, diff));
            }
        }

        return (false, "");
    }
}

