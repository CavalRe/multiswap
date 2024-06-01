// SPDX-License-Identifier: Business Source License 1.1
// Copyright (C) 2020-2023, CavalRe Inc. All rights reserved.
// See the file LICENSE.md for licensing terms.
pragma solidity 0.8.24;

interface IUsers {
    error CannotModify(address user);

    error InvalidDiscount(uint256 discount_);

    error UserNotAllowed(address user_);

    error ZeroAddress();

    function isAllowed(address user_) external view returns (bool);

    function discount(address user_) external view returns (uint256);

    function setDiscount(address user_, uint256 discount_) external;
}
