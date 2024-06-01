// SPDX-License-Identifier: Business Source License 1.1
// Copyright (C) 2020-2023, CavalRe Inc. All rights reserved.
// See the file LICENSE.md for licensing terms.
pragma solidity 0.8.24;

import {IUsers} from "./interfaces/IUsers.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract Users is IUsers, Ownable2Step {
    uint256 internal constant ONE = 1e18;
    uint256 internal constant HALF = 5e17;

    mapping(address => bool) internal _isBlocked;
    mapping(address => uint256) internal _discount;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function isAllowed(address user_) public view returns (bool) {
        return !_isBlocked[user_];
    }

    function discount(address user_) public view returns (uint256) {
        return _discount[user_];
    }

    function setDiscount(address user_, uint256 discount_) public onlyOwner {
        if (_isBlocked[user_]) revert UserNotAllowed(user_);
        if (user_ == address(0)) revert ZeroAddress();
        if (discount_ > ONE) revert InvalidDiscount(discount_);
        _discount[user_] = discount_;
    }
}
