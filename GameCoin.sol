// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract GameCoinContract {
    address public owner;
    address public usdtAddress;
    mapping(address => uint256) public gameCoinBalance;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    event USDTDeposited(address indexed user, uint256 amount);
    event USDTWithdrawn(address indexed to, uint256 amount);
    event GameCoinIssued(address indexed user, uint256 amount);
    event GameCoinUsed(address indexed user, uint256 amount);

    constructor(address _usdtAddress) {
        require(_usdtAddress != address(0), "Invalid USDT address");
        owner = msg.sender;
        usdtAddress = _usdtAddress;
    }

    function depositAndApproveUSDT(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");

        // Initialize the USDT contract
        IERC20 usdt = IERC20(usdtAddress);

        // Approve the contract to spend user's USDT
        require(usdt.approve(address(this), amount), "Approve failed");

        // Transfer USDT from the user to this contract
        require(usdt.transferFrom(msg.sender, address(this), amount), "USDT transfer failed");

        // Increase the GameCoin balance of the sender
        gameCoinBalance[msg.sender] += amount;

        emit USDTDeposited(msg.sender, amount);
        emit GameCoinIssued(msg.sender, amount);
    }

    function withdrawUSDT(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Amount must be greater than zero");

        IERC20 usdt = IERC20(usdtAddress);
        require(usdt.balanceOf(address(this)) >= amount, "Insufficient USDT balance in contract");

        // Transfer USDT to the specified address
        require(usdt.transfer(to, amount), "USDT transfer failed");

        emit USDTWithdrawn(to, amount);
    }

    function getContractUSDTBalance() external view returns (uint256) {
        IERC20 usdt = IERC20(usdtAddress);
        return usdt.balanceOf(address(this));
    }

    function getAllowance(address user) external view returns (uint256) {
        IERC20 usdt = IERC20(usdtAddress);
        return usdt.allowance(user, address(this));
    }

    function useGameCoin(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(gameCoinBalance[msg.sender] >= amount, "Insufficient GameCoin balance");

        // Deduct the GameCoin from the user's balance
        gameCoinBalance[msg.sender] -= amount;

        // Add the used GameCoin to the contract's balance (for reuse or tracking purposes)
        gameCoinBalance[address(this)] += amount;

        emit GameCoinUsed(msg.sender, amount);
    }
}
