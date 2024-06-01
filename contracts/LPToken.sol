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

import {ILPToken} from "./interfaces/ILPToken.sol";
import {Users} from "./Users.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";

contract LPToken is ILPToken, ERC20, Users {
    using FixedPointMathLib for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalTokens;
    uint256 internal _tokensPerShare;

    uint256 internal _protocolFee;
    address internal _protocolFeeRecipient;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) Users(_msgSender()) {
        _tokensPerShare = 1e18;
        _protocolFeeRecipient = _msgSender();
    }

    function totalTokens() public view returns (uint256) {
        return _totalTokens;
    }

    function tokensPerShare() public view returns (uint256) {
        return _tokensPerShare;
    }

    function tokensOf(address account) public view returns (uint256) {
        return balanceOf(account).mulWadUp(_tokensPerShare);
    }

    function approve(
        address spender,
        uint256 shares
    ) public override returns (bool) {
        if (_isBlocked[spender]) revert UserNotAllowed(spender);
        return super.approve(spender, shares);
    }

    function transferFrom(
        address from,
        address to,
        uint256 shares
    ) public override returns (bool) {
        address spender = _msgSender();
        if (_isBlocked[spender]) revert UserNotAllowed(spender);
        return super.transferFrom(from, to, shares);
    }

    function _update(
        address from,
        address to,
        uint256 shares
    ) internal override {
        if (_isBlocked[to]) revert UserNotAllowed(to);
        return super._update(from, to, shares);
    }

    function protocolFee() public view returns (uint256) {
        return _protocolFee;
    }

    function protocolFeeRecipient() public view returns (address) {
        return _protocolFeeRecipient;
    }

    function setProtocolFee(uint256 fee) public onlyOwner {
        if (fee > HALF) revert InvalidProtocolFee(fee);
        _protocolFee = fee;
    }

    function setProtocolFeeRecipient(address recipient) public onlyOwner {
        if (recipient == address(0)) revert ZeroAddress();
        if (_isBlocked[recipient]) revert UserNotAllowed(recipient);
        _protocolFeeRecipient = recipient;
    }
}
