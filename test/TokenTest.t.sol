// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {FunToken} from "../src/FunToken.sol";

contract TokenTest is Test {
    FunToken public token;

    address owner = 0xD61057659842d70e76AB06EE6eC37b2257454c60;
    address zeroAddress = 0x0000000000000000000000000000000000000000;
    address tester = makeAddr("tester");
    address tester2 = makeAddr("tester2");

    event Transfer(address from, address to, uint256 value);

    function setUp() public {
        token = new FunToken();
    }

    function testName() public {
        assertEq(token.name(), "Fun Token");
    }

    function testSymbol() public {
        assertEq(token.symbol(), "FNT");
    }

    function testDecimals() public {
        assertEq(token.decimals(), 18);
    }

    function testBalanceOf() public {
        assertEq(token.balanceOf(owner), 1_000_000e18);
    }

    function testTransfer() public {
        uint256 balanceOwner = token.balanceOf(owner);
        vm.prank(owner);
        // #TODO: For some reasons the logs are different while they appear to be the same
        // vm.expectEmit();
        // emit Transfer(owner, tester, 1000e18);
        bool success = token.transfer(tester, 1000e18);
        uint256 newBalanceOwner = token.balanceOf(owner);
        uint256 balanceTester = token.balanceOf(tester);
        assertEq(balanceOwner - 1000e18, newBalanceOwner);
        assertEq(balanceTester, 1000e18);
        assertEq(success, true);
    }

    function testTransferRevertsOnAddressZeroTransfers() public {
        vm.expectRevert(0x96c6fd1e); // InvalidSender
        vm.prank(zeroAddress);
        token.transfer(tester, 1000e18);

        vm.expectRevert(0xec442f05); // InvalidReceiver
        token.transfer(zeroAddress, 1000e18);
    }

    function testTransferRevertsOnInsufficentBalance() public {
        vm.expectRevert(0x296ce993); // ERC20InsufficentBalance
        token.transfer(tester, 1000e18);
    }

    function testApprove() public {
        uint256 allowance = token.allowance(owner, tester);
        assertEq(allowance, 0);
        vm.prank(owner);
        token.approve(tester, 1000e18);
        uint256 newAllowance = token.allowance(owner, tester);
        assertEq(newAllowance, allowance + 1000e18);
    }

    function testApproveRevertsOnAddressZeroApproval() public {
        vm.prank(zeroAddress);
        vm.expectRevert(0xe602df05); // ERC20InvalidApprover
        token.approve(tester, 1000e18);

        vm.expectRevert(0x94280d62);
        token.approve(zeroAddress, 1000e18);
    }

    function testTransferFromRevertsOnAddressZeroTransfers() public {
        vm.expectRevert(0x96c6fd1e); // InvalidSender
        token.transferFrom(address(0), tester, 1000e18);
        vm.expectRevert(0xec442f05); // InvalidReceiver
        token.transferFrom(owner, address(0), 1000e18);
    }

    function testTransferFromRevertsOnInsufficentBalance() public {
        vm.expectRevert(0x296ce993); // ERC20InsufficentBalance
        token.transferFrom(tester, owner, 1000e18);
    }

    function testTransferFromRevertsOnInsufficentAllowance() public {
        vm.expectRevert(0xfb8f41b2); // ERC20InsufficentAllowance
        vm.prank(tester);
        token.transferFrom(owner, tester, 1000e18);
    }

    function testTransferFromTransfersFromCaller() public {
        uint256 ownerBalance = token.balanceOf(owner);
        uint256 toBalance = token.balanceOf(tester);
        vm.prank(owner);
        bool success = token.transferFrom(owner, tester, 1000e18);
        uint256 newOwnerBalance = token.balanceOf(owner);
        uint256 newToBalance = token.balanceOf(tester);
        assertEq(ownerBalance - 1000e18, newOwnerBalance);
        assertEq(toBalance + 1000e18, newToBalance);
        assertEq(success, true);
    }

    function testTransferFromTransfersWithAllowance() public {
        vm.prank(owner);
        token.approve(tester, 1000e18);
        uint256 ownerBalance = token.balanceOf(owner);
        uint256 toBalance = token.balanceOf(tester);
        uint256 allowance = token.allowance(owner, tester);
        vm.prank(tester);
        token.transferFrom(owner, tester, 1000e18);
        uint256 newOwnerBalance = token.balanceOf(owner);
        uint256 newToBalance = token.balanceOf(tester);
        uint256 newAllowance = token.allowance(owner, tester);
        assertEq(newOwnerBalance, ownerBalance - 1000e18);
        assertEq(newToBalance, toBalance + 1000e18);
        assertEq(newAllowance, allowance - 1000e18);
    }

    function testBurnRevertsOnZeroAddress() public {
        vm.prank(zeroAddress);
        vm.expectRevert(0x96c6fd1e); // ERC20InvalidSender
        token.burn(1000e18);
    }

    function testBurnRevertsOnInsufficentBalance() public {
        vm.prank(tester);
        vm.expectRevert(0x296ce993); // ERC20InsufficentBalance
        token.burn(1000e18);
    }

    function testBurnBurnsTokens() public {
        uint256 ownerBalance = token.balanceOf(owner);
        vm.prank(owner);
        bool success = token.burn(1000e18);
        uint256 newOwnerBalance = token.balanceOf(owner);
        assertEq(newOwnerBalance, ownerBalance - 1000e18);
        assertEq(success, true);
    }
}
