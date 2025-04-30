// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestUSDC is ERC20 {
    address public owner;

    constructor() ERC20("Test USDC", "USDC") {
        owner = msg.sender;
        _mint(msg.sender, 1000000 * 10 ** decimals()); // 初期供給量をミント
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
