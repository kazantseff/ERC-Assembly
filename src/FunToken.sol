// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FunToken {
    mapping(address account => uint256) public balances;

    mapping(address account => mapping(address spender => uint256))
        private allowances;

    uint256 constant TOTAL_SUPPLY = 1_000_000e18;

    address constant OWNER = 0xD61057659842d70e76AB06EE6eC37b2257454c60;

    bytes32 constant nameLength =
        0x0000000000000000000000000000000000000000000000000000000000000009;
    // Fun Token
    bytes32 constant nameData =
        0x46756e20546f6b656e0000000000000000000000000000000000000000000000;

    bytes32 constant sybmolLength =
        0x0000000000000000000000000000000000000000000000000000000000000003;
    // FNT
    bytes32 constant symbolData =
        0x464e540000000000000000000000000000000000000000000000000000000000;

    bytes32 constant TRANSFER_EVENT =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    bytes32 constant APPROVAL_EVENT =
        0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

    constructor() {
        assembly {
            mstore(0x00, OWNER)
            mstore(0x20, 0x00)
            sstore(keccak256(0x00, 0x40), TOTAL_SUPPLY)
        }
    }

    function name() public pure returns (string memory) {
        assembly {
            mstore(0x00, 0x20)
            mstore(0x20, nameLength)
            mstore(0x40, nameData)
            return(0x00, 0x60)
        }
    }

    function symbol() public pure returns (string memory) {
        assembly {
            mstore(0x00, 0x20)
            mstore(0x20, sybmolLength)
            mstore(0x40, symbolData)
            return(0x00, 0x60)
        }
    }

    function decimals() public pure returns (uint256) {
        assembly {
            mstore(0x00, 0x12)
            return(0x00, 0x20)
        }
    }

    function totalSupply() public pure returns (uint256) {
        assembly {
            mstore(0x00, TOTAL_SUPPLY)
            return(0x00, 0x20)
        }
    }

    function balanceOf(address) public view returns (uint256) {
        assembly {
            // offset is 4 bytes because the first 4 bytes are function selector
            mstore(0xa0, calldataload(0x04))
            // Store the slot number of _balances
            mstore(0xc0, 0x00)
            // keccak hash of the address and slot == keccak256(abi.encode(owner, 0))
            mstore(0xe0, sload(keccak256(0xa0, 0x40)))
            return(0xe0, 0x20)
        }
    }

    function transfer(address, uint256) public returns (bool) {
        assembly {
            let owner := caller()
            let to := calldataload(0x04)
            let value := calldataload(0x24)

            if iszero(owner) {
                // ERC20InvalidSender
                mstore(0x00, 0x96c6fd1e)
                revert(0x1c, 0x04)
            }

            if iszero(to) {
                // ERC20InvalidReceiver
                mstore(0x00, 0xec442f05)
                revert(0x1c, 0x04)
            }

            mstore(0x00, owner)
            mstore(0x20, 0x00)
            let ownerSlot := keccak256(0x00, 0x40)

            mstore(0x00, to)
            mstore(0x20, 0x00)
            let toSlot := keccak256(0x00, 0x40)

            let ownerBalance := sload(ownerSlot)

            if lt(ownerBalance, value) {
                // ERC20InsufficentBalance
                mstore(0x00, 0x296ce993)
                revert(0x1c, 0x04)
            }

            sstore(ownerSlot, sub(ownerBalance, value))
            sstore(toSlot, add(sload(toSlot), value))

            // Emit transfer event
            mstore(0x00, value)
            log3(0x00, 0x20, TRANSFER_EVENT, owner, to)

            // Return true
            mstore(0x00, 0x01)
            return(0x00, 0x20)
        }
    }

    function allowance(address, address) public view returns (uint256) {
        assembly {
            // Calldataload returns 32 bytes starting at an offset
            let owner := calldataload(0x04)
            let spender := calldataload(0x24)

            // Store the owner
            mstore(0x00, owner)
            // Store the slot of mapping in storage
            mstore(0x20, 0x01)
            // Calcualte the owner slot
            let ownerSlot := keccak256(0x00, 0x40)

            // Store spender address
            mstore(0x00, spender)
            // Store ownerSlot
            mstore(0x20, ownerSlot)
            // Calculate the hash of (spender, ownerSlot)
            let fullLocation := keccak256(0x00, 0x40)

            mstore(0x00, sload(fullLocation))
            return(0x00, 0x20)
        }
    }

    function approve(address, uint256) public returns (bool) {
        assembly {
            let owner := caller()
            let spender := calldataload(0x04)
            let value := calldataload(0x24)

            if iszero(owner) {
                // ERC20InvalidApprover
                mstore(0x00, 0xe602df05)
                revert(0x1c, 0x04)
            }

            if iszero(spender) {
                // ERC20InvalidSpender
                mstore(0x00, 0x94280d62)
                revert(0x1c, 0x04)
            }

            mstore(0x00, owner)
            mstore(0x20, 0x01)
            let ownerSlot := keccak256(0x00, 0x40)

            mstore(0x00, spender)
            mstore(0x20, ownerSlot)
            let fullLocation := keccak256(0x00, 0x40)

            sstore(fullLocation, value)

            // Emit Approval event
            mstore(0x00, value)
            log3(0x00, 0x20, APPROVAL_EVENT, owner, spender)

            //  Return true
            mstore(0x00, 0x01)
            return(0x00, 0x20)
        }
    }

    function transferFrom(address, address, uint256) public returns (bool) {
        assembly {
            let spender := caller()
            let from := calldataload(0x04)
            let to := calldataload(0x24)
            let value := calldataload(0x44)

            // Cannot transfer from address(0) or to address(0)
            if iszero(from) {
                // ERC20InvalidSender
                mstore(0x00, 0x96c6fd1e)
                revert(0x1c, 0x04)
            }

            if iszero(to) {
                // ERC20InvalidReceiver
                mstore(0x00, 0xec442f05)
                revert(0x1c, 0x04)
            }

            // Calculate _balances slots
            mstore(0x00, from)
            mstore(0x20, 0)
            let fromBalanceSlot := keccak256(0x00, 0x40)
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x00, 0x40)

            let fromBalance := sload(fromBalanceSlot)
            // Check if there is enough tokens
            if lt(fromBalance, value) {
                // ERC20InsufficentBalance
                mstore(0x00, 0x296ce993)
                revert(0x1c, 0x04)
            }

            // If caller is the from address => proceeds with the transfer
            if eq(spender, from) {
                // Update mappings
                sstore(fromBalanceSlot, sub(fromBalance, value))
                sstore(toBalanceSlot, add(sload(toBalanceSlot), value))

                // Emit transfer event
                mstore(0x00, value)
                log3(0x00, 0x20, TRANSFER_EVENT, from, to)

                // Return true
                mstore(0x00, 0x01)
                return(0x00, 0x20)
            }

            // If caller is not from address => check allowance
            mstore(0x00, from)
            mstore(0x20, 0x01)
            let allowanceOwnerSlot := keccak256(0x00, 0x40)
            mstore(0x00, spender)
            mstore(0x20, allowanceOwnerSlot)
            let allowanceFullLocation := keccak256(0x00, 0x40)

            // Storing it in memory to avoid accesing storage multiple times
            mstore(0x00, sload(allowanceFullLocation))

            // If allowance is insufficent => revert
            if lt(mload(0x00), value) {
                // ERC20InsufficentAllowance
                mstore(0x00, 0xfb8f41b2)
                revert(0x1c, 0x04)
            }

            // Deduct the allowance
            sstore(allowanceFullLocation, sub(mload(0x00), value))
            // Update _balances
            sstore(fromBalanceSlot, sub(fromBalance, value))
            sstore(toBalanceSlot, add(sload(toBalanceSlot), value))

            // Emit transfer event
            mstore(0x00, value)
            log3(0x00, 0x20, TRANSFER_EVENT, from, to)

            // Return true
            mstore(0x00, 0x01)
            return(0x00, 0x20)
        }
    }

    function burn(uint256) public returns (bool) {
        assembly {
            let from := caller()
            let value := calldataload(0x04)

            if iszero(from) {
                // ERC20InvalidSender
                mstore(0x00, 0x96c6fd1e)
                revert(0x1c, 0x04)
            }

            mstore(0x00, from)
            mstore(0x20, 0x00)
            let ownerSlot := keccak256(0x00, 0x40)

            mstore(0x00, sload(ownerSlot))
            if lt(mload(0x00), value) {
                // ERC20InsufficentBalance
                mstore(0x00, 0x296ce993)
                revert(0x1c, 0x04)
            }

            sstore(ownerSlot, sub(mload(0x00), value))

            // Emit transfer event
            mstore(0x00, value)
            log3(0x00, 0x20, TRANSFER_EVENT, from, 0x00)

            // Return true
            mstore(0x00, 0x01)
            return(0x00, 0x20)
        }
    }
}
