/**
 *Submitted for verification at polygonscan.com on 2024-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint amount) external returns (bool);
}

interface ISushiSwapRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(
        uint amountIn, 
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

contract SushiSwapExecutor { 
    address private constant SUSHI_SWAP_ROUTER_ADDRESS = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; // SushiSwap Router
    address public owner;

    ISushiSwapRouter public sushiSwapRouter;

    constructor() {
        owner = msg.sender;
        sushiSwapRouter = ISushiSwapRouter(SUSHI_SWAP_ROUTER_ADDRESS);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    // Fetch token balance of any token for the owner of this contract
    function getTokenBalance(address tokenAddress) public view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(address(this));
    }

    // Approve tokens for swapping on SushiSwap
    function approveToken(address aquien, address tokenAddress, uint256 amount) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.approve(aquien, amount);
    }

    // Execute swap on SushiSwap from USDT to WETH
    function executeSwap(address aquien, address tokenAddress, address totoken) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        // Approve SushiSwap to spend USDT
        approveToken(aquien, tokenAddress, token.balanceOf(address(this)));

        // Path for the swap: USDT -> WETH
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = totoken;

        // Calculate amountOutMin (with 5% slippage)
        uint[] memory amountsOut = sushiSwapRouter.getAmountsOut(token.balanceOf(address(this)), path);
        uint amountOutMin = amountsOut[1] * 95 / 100; // 5% slippage

        // Perform the swap
        sushiSwapRouter.swapExactTokensForTokens(
            token.balanceOf(address(this)),
            amountOutMin,
            path,
            address(this),
            block.timestamp + 1200 // 20-minute deadline
        );
    }

    function withdrawETH() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        payable(msg.sender).transfer(contractBalance);
    }

    function withdrawETH(uint256 _value) external onlyOwner {
        payable(msg.sender).transfer(_value);
    }

    // Withdraw tokens from the contract
    function withdrawTokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }

    function withdrawTokens(address tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, _amount), "Transfer failed");
    }

    receive() external payable {}

    fallback() external payable {}
}
