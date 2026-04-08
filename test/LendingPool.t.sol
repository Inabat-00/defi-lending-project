// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/LendingPool.sol";
import "../src/Token.sol";

contract LendingPoolTest is Test {
    LendingPool pool;
    Token token;

    address user = address(1);

    function setUp() public {
        token = new Token("Test", "TST");
        pool = new LendingPool(address(token));

        token.mint(address(this), 1e24);
        token.transfer(user, 1e21);

        token.approve(address(pool), type(uint256).max);

        vm.startPrank(user);
        token.approve(address(pool), type(uint256).max);
        vm.stopPrank();
    }

    function testDeposit() public {
        pool.deposit(100);
        assertEq(pool.deposited(address(this)), 100);
    }

    function testBorrow() public {
        pool.deposit(100);
        pool.borrow(50);

        assertEq(pool.borrowed(address(this)), 50);
    }

    function testBorrowExceedsLTV() public {
        pool.deposit(100);

        vm.expectRevert();
        pool.borrow(80);
    }

    function testRepay() public {
        pool.deposit(100);
        pool.borrow(50);

        pool.repay(20);

        assertEq(pool.borrowed(address(this)), 30);
    }

    function testWithdraw() public {
        pool.deposit(100);
        pool.withdraw(50);

        assertEq(pool.deposited(address(this)), 50);
    }

    function testWithdrawFail() public {
        pool.deposit(100);
        pool.borrow(70);

        vm.expectRevert();
        pool.withdraw(50);
    }

    function testLiquidation() public {
        vm.startPrank(user);

        pool.deposit(100);
        pool.borrow(75);

        vm.stopPrank();

        vm.warp(block.timestamp + 365 days);

        pool.liquidate(user);

        assertEq(pool.deposited(user), 0);
    }

    function testInterest() public {
        pool.deposit(100);
        pool.borrow(50);

        vm.warp(block.timestamp + 365 days);

        uint256 debt = pool.getDebt(address(this));

        assertGt(debt, 50);
    }

    function testZeroDepositFail() public {
        vm.expectRevert();
        pool.deposit(0);
    }

    function testZeroBorrowFail() public {
        vm.expectRevert();
        pool.borrow(0);
    }
}
