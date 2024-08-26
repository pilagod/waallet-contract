// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IOracle } from "src/interface/IOracle.sol";

interface IToken {
    function decimals() external view returns (uint8);
}

contract MockOracle is IOracle {
    IToken token;

    constructor(IToken token_) {
        token = token_;
    }

    function decimals() external view returns (uint8) {
        return token.decimals();
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = uint80(block.timestamp);
        // Default the ratio to 1 by unit.
        // one unit of native / one unit of token = 1
        answer = int256(1e18 / 10 ** token.decimals());
        startedAt = block.timestamp;
        updatedAt = block.timestamp;
        answeredInRound = roundId;
    }
}
