// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract LendingPool {
    IERC20 public token;

    mapping(address => uint256) public deposited;
    mapping(address => uint256) public borrowed;
    mapping(address => uint256) public lastUpdate;

    uint256 public constant LTV = 75; // 75%
    uint256 public interestRate = 5; // 5% yearly

    constructor(address _token) {
        token = IERC20(_token);
    }

    // ===== Deposit =====
    function deposit(uint256 amount) external {
        require(amount > 0, "zero deposit");

        token.transferFrom(msg.sender, address(this), amount);

        deposited[msg.sender] += amount;
        lastUpdate[msg.sender] = block.timestamp;
    }

    // ===== Borrow =====
    function borrow(uint256 amount) external {
        require(amount > 0, "zero borrow");

        uint256 maxBorrow = (deposited[msg.sender] * LTV) / 100;

        require(borrowed[msg.sender] + amount <= maxBorrow, "exceeds LTV");

        borrowed[msg.sender] += amount;
        lastUpdate[msg.sender] = block.timestamp;

        token.transfer(msg.sender, amount);
    }

    // ===== Repay =====
    function repay(uint256 amount) external {
        require(amount > 0, "zero repay");

        token.transferFrom(msg.sender, address(this), amount);

        borrowed[msg.sender] -= amount;
    }

    // ===== Withdraw =====
    function withdraw(uint256 amount) external {
        require(amount > 0, "zero withdraw");

        uint256 remaining = deposited[msg.sender] - amount;
        uint256 maxBorrow = (remaining * LTV) / 100;

        require(borrowed[msg.sender] <= maxBorrow, "health factor < 1");

        deposited[msg.sender] -= amount;

        token.transfer(msg.sender, amount);
    }

    // ===== Liquidate =====
    function liquidate(address user) external {
    uint256 maxBorrow = (deposited[user] * LTV) / 100;

    uint256 debt = getDebt(user); 

    require(debt > maxBorrow, "not liquidatable");

    deposited[user] = 0;
    borrowed[user] = 0;
}

    // ===== Interest =====
    function getDebt(address user) public view returns (uint256) {
        uint256 timePassed = block.timestamp - lastUpdate[user];

        uint256 interest = (borrowed[user] * interestRate * timePassed)
            / (365 days * 100);

        return borrowed[user] + interest;
    }
}