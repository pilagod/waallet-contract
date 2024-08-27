// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IUniswapV3SwapRouter } from "src/interface/IUniswapV3SwapRouter.sol";
import { WETH } from "src/token/WETH.sol";
import { IERC20 } from
    "@openzeppelin-contracts/5.0/contracts/token/ERC20/IERC20.sol";

contract MockUniswapV3SwapRouter is IUniswapV3SwapRouter {
    WETH weth;

    constructor(WETH weth_) {
        weth = weth_;
    }

    function unwrapWETH9(
        uint256 amountMinimum,
        address recipient
    ) external payable {
        uint256 balance = weth.balanceOf(address(this));
        require(balance > 0 && balance >= amountMinimum, "Insufficient WETH9");
        weth.withdraw(balance);
        (bool success,) = recipient.call{ value: balance }(new bytes(0));
        require(success, "STE");
    }

    function exactInputSingle(
        IUniswapV3SwapRouter.ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut) {
        require(
            IERC20(params.tokenIn).balanceOf(msg.sender) >= params.amountIn,
            "Token in balance is not enough"
        );
        require(
            IERC20(params.tokenOut).balanceOf(address(this))
                >= params.amountOutMinimum,
            "Token out balance is not enough"
        );
        require(params.deadline >= block.timestamp, "Swap had expired");

        IERC20(params.tokenIn).transferFrom(
            msg.sender, address(this), params.amountIn
        );
        IERC20(params.tokenOut).transfer(
            params.recipient, params.amountOutMinimum
        );

        return params.amountOutMinimum;
    }
}
