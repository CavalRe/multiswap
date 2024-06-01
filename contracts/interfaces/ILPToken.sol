// SPDX-License-Identifier: Business Source License 1.1
/**
 * This file is a modified version of a file from the OpenZeppelin project:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/ERC20.sol
 *
 * The original file is licensed under the MIT License, a copy of which can be found at:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/LICENSE
 */
// Copyright (C) 2020-2023, CavalRe Inc. All rights reserved.
// See the file LICENSE.md for licensing terms.
pragma solidity 0.8.24;

import {IUsers} from "./IUsers.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILPToken is IUsers {
    event DistributeFee(
        uint256 indexed txCount,
        uint256 lpAmount,
        uint256 protocolAmount
    );

    error InvalidProtocolFee(uint256 fee);

    function totalTokens() external view returns (uint256);

    function tokensPerShare() external view returns (uint256);

    function tokensOf(address account) external view returns (uint256);

    function protocolFee() external view returns (uint256);

    function protocolFeeRecipient() external view returns (address);

    function setProtocolFee(uint256 fee) external;

    function setProtocolFeeRecipient(address recipient) external;
}
