// SPDX-License-Identifier: Business Source License 1.1
// Copyright (C) 2020-2023, CavalRe Inc. All rights reserved.
// See the file LICENSE.md for licensing terms.
pragma solidity 0.8.24;

import {PoolState, AssetState, State, Order} from "./interfaces/IPool.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";

library Quote {
    using FixedPointMathLib for uint256;

    struct Stack {
        uint256 fee;
        uint256 discount;
        uint256 scaledValueIn;
        uint256 poolOut;
        uint256 lastPoolBalance;
        uint256 scaledPoolOut;
        uint256 poolIn;
        uint256 poolAlloc;
        uint256 scaledValueOut;
    }

    function _multiswap(
        State storage self,
        address sender,
        Order[] memory payOrders,
        Order[] memory receiveOrders
    )
        internal
        view
        returns (uint256[] memory receiveAmounts, uint256 feeAmount)
    {
        Stack memory stack;
        address poolAddress = self.pool.token;
        if (
            payOrders[0].token == poolAddress &&
            payOrders[0].amount == self.pool.balance
        ) {
            receiveAmounts = new uint256[](self.assetAddresses.length);
            for (uint256 i; i < self.assetAddresses.length; i++) {
                receiveAmounts[i] = IERC20(self.assetAddresses[i]).balanceOf(
                    poolAddress
                );
            }
            return (receiveAmounts, feeAmount);
        }

        receiveAmounts = new uint256[](receiveOrders.length);

        {
            // Compute fee
            {
                for (uint256 i; i < receiveOrders.length; i++) {
                    stack.fee += receiveOrders[i].amount.mulWadUp(
                        self.assets[receiveOrders[i].token].fee
                    );
                }
                uint256 discount_ = self.discount[sender];
                if (stack.fee > 0 && discount_ > 0) {
                    stack.fee = stack.fee.mulWadUp(1e18 - discount_);
                }
            }

            // Compute scaledValueIn
            {
                // Contribution from assets only
                for (uint256 i; i < payOrders.length; i++) {
                    address token_ = payOrders[i].token;
                    if (token_ != self.pool.token) {
                        AssetState storage assetIn = self.assets[token_];
                        uint256 amount_ = payOrders[i].amount *
                            assetIn.conversion; // Convert to canonical
                        stack.scaledValueIn += assetIn.scale.fullMulDiv(
                            amount_,
                            assetIn.balance + amount_
                        );
                    }
                }

                stack.poolAlloc = stack.fee;
                if (receiveOrders[0].token == self.pool.token) {
                    stack.poolAlloc += receiveOrders[0].amount.mulWadUp(
                        1e18 - stack.fee
                    );
                }
                stack.lastPoolBalance = self.pool.balance;
                stack.scaledPoolOut = stack.scaledValueIn.mulWadUp(
                    stack.poolAlloc
                );
                if (payOrders[0].token == self.pool.token) {
                    stack.poolIn = payOrders[0].amount.mulWadUp(
                        self.pool.tokensPerShare
                    );
                    stack.poolOut = stack.poolAlloc.fullMulDiv(
                        stack.scaledValueIn.mulWadUp(
                            stack.lastPoolBalance - stack.poolIn
                        ) + self.pool.scale.mulWadUp(stack.poolIn),
                        self.pool.scale - stack.scaledPoolOut
                    );
                    stack.scaledValueIn += self.pool.scale.fullMulDiv(
                        stack.poolIn,
                        stack.lastPoolBalance + stack.poolOut - stack.poolIn
                    );
                    feeAmount = stack.poolOut;
                } else {
                    stack.poolOut = stack.lastPoolBalance.fullMulDiv(
                        stack.scaledPoolOut,
                        self.pool.scale - stack.scaledPoolOut
                    );
                    if (stack.poolAlloc > 0) {
                        feeAmount = stack.poolOut.fullMulDiv(
                            stack.fee,
                            stack.poolAlloc
                        );
                    }
                }
            }

            // Compute receiveAmounts
            {
                address receiveToken;
                uint256 allocation;
                for (uint256 i; i < receiveOrders.length; i++) {
                    receiveToken = receiveOrders[i].token;
                    allocation = receiveOrders[i].amount.mulWadUp(
                        1e18 - stack.fee
                    );
                    stack.scaledValueOut = stack.scaledValueIn.mulWadUp(
                        allocation
                    );
                    if (receiveToken == self.pool.token) {
                        receiveAmounts[i] = (stack.poolOut - feeAmount)
                            .divWadUp(self.pool.tokensPerShare);
                    } else {
                        AssetState storage assetOut = self.assets[receiveToken];
                        receiveAmounts[i] =
                            assetOut.balance.fullMulDiv(
                                stack.scaledValueOut,
                                assetOut.scale + stack.scaledValueOut
                            ) /
                            assetOut.conversion; // Convert from canonical
                    }
                }
            }
        }
    }

    function multiswap(
        State storage self,
        Order[] memory payOrders,
        Order[] memory receiveOrders
    )
        internal
        view
        returns (uint256[] memory receiveAmounts, uint256 feeAmount)
    {
        (receiveAmounts, feeAmount) = _multiswap(
            self,
            msg.sender,
            payOrders,
            receiveOrders
        );
    }

    function swap(
        State storage self,
        address payToken,
        address receiveToken,
        uint256 payAmount
    ) internal view returns (uint256 receiveAmount, uint256 feeAmount) {
        Order[] memory payOrders = new Order[](1);
        payOrders[0] = Order(payToken, payAmount);
        Order[] memory receiveOrders = new Order[](1);
        receiveOrders[0] = Order(receiveToken, 1e18);
        (uint256[] memory _receiveAmounts, uint256 _feeAmount) = _multiswap(
            self,
            msg.sender,
            payOrders,
            receiveOrders
        );
        receiveAmount = _receiveAmounts[0];
        feeAmount = _feeAmount;
    }

    function stake(
        State storage self,
        address payToken,
        uint256 payAmount
    ) internal view returns (uint256 receiveAmount, uint256 feeAmount) {
        Order[] memory payOrders = new Order[](1);
        payOrders[0] = Order(payToken, payAmount);
        Order[] memory receiveOrders = new Order[](1);
        receiveOrders[0] = Order(self.pool.token, 1e18);
        (uint256[] memory _receiveAmounts, uint256 _feeAmount) = _multiswap(
            self,
            msg.sender,
            payOrders,
            receiveOrders
        );
        receiveAmount = _receiveAmounts[0];
        feeAmount = _feeAmount;
    }

    function unstake(
        State storage self,
        address receiveToken,
        uint256 payAmount
    ) public view returns (uint256 receiveAmount, uint256 feeAmount) {
        Order[] memory payOrders = new Order[](1);
        payOrders[0] = Order(self.pool.token, payAmount);
        Order[] memory receiveOrders = new Order[](1);
        receiveOrders[0] = Order(receiveToken, 1e18);
        (uint256[] memory _receiveAmounts, uint256 _feeAmount) = _multiswap(
            self,
            msg.sender,
            payOrders,
            receiveOrders
        );
        receiveAmount = _receiveAmounts[0];
        feeAmount = _feeAmount;
    }

    function quoteAddLiquidity(
        address token,
        uint256 amount
    ) public view returns (uint256[] memory payAmounts) {
        // AssetState storage assetIn;
        // payAmounts = new uint256[](self.assetAddresses.length);
        // uint256 g;
        // if (token == self.pool.token) {
        //     g = (self.pool.balance +
        //         amount.mulWadUp(self.pool.tokensPerShare)).divWadUp(
        //             self.pool.balance
        //         );
        // } else {
        //     assetIn = self.assets[token];
        //     if (assetIn.decimals == 0) revert AssetNotFound(token);
        //     g = (assetIn.balance + amount * assetIn.conversion).divWadUp(
        //         assetIn.balance
        //     );
        // }
        // uint256 payAmount;
        // for (uint256 i; i < self.assetAddresses.length; i++) {
        //     assetIn = self.assets[self.assetAddresses[i]];
        //     if (
        //         (assetIn.token == token) ||
        //         (assetIn.token == _wrappedNativeAddress && token == address(0))
        //     ) {
        //         payAmount = amount;
        //     } else {
        //         payAmount =
        //             (assetIn.balance.mulWadUp(g) - assetIn.balance) /
        //             assetIn.conversion;
        //     }
        //     payAmounts[i] = payAmount;
        // }
    }

    function removeLiquidity(
        State storage self,
        uint256 amount
    ) public view returns (uint256[] memory receiveAmounts, uint256 feeAmount) {
        Order[] memory payOrders = new Order[](1);
        payOrders[0] = Order(self.pool.token, amount);
        Order[] memory receiveOrders = new Order[](self.assetAddresses.length);
        uint256 allocation;
        uint256 totalAllocation;
        for (uint256 i; i < self.assetAddresses.length - 1; i++) {
            allocation = self.assets[self.assetAddresses[i]].scale.divWadUp(
                self.pool.scale
            );
            totalAllocation += allocation;
            receiveOrders[i] = Order(self.assetAddresses[i], allocation);
        }
        allocation = 1e18 - totalAllocation;
        receiveOrders[self.assetAddresses.length - 1] = Order(
            self.assetAddresses[self.assetAddresses.length - 1],
            allocation
        );
        (receiveAmounts, feeAmount) = _multiswap(
            self,
            msg.sender,
            payOrders,
            receiveOrders
        );
    }

    // function _multiswap(
    //     address sender,
    //     address[] memory payTokens,
    //     uint256[] memory amounts,
    //     address[] memory receiveTokens,
    //     uint256[] memory allocations,
    //     uint256[] memory minReceiveAmounts
    // )
    //     private
    //     returns (uint256[] memory receiveAmounts, uint256 feeAmount)
    // {
    //     // _txCount++;

    //     // if (payTokens[0] == self.pool.token && amounts[0] == totalSupply()) {
    //     //     return _disable(sender);
    //     // }

    //     // (receiveAmounts, feeAmount) = _multiswap(
    //     //     sender,
    //     //     payTokens,
    //     //     amounts,
    //     //     receiveTokens,
    //     //     allocations
    //     // );

    //     // // Check receiveAmounts
    //     // {
    //     //     for (uint256 i; i < receiveTokens.length; i++) {
    //     //         if (receiveAmounts[i] < minReceiveAmounts[i]) {
    //     //             revert InsufficientReceiveAmount(
    //     //                 minReceiveAmounts[i],
    //     //                 receiveAmounts[i]
    //     //             );
    //     //         }
    //     //     }
    //     // }

    //     // // Transfer tokens to the pool
    //     // for (uint256 i; i < payTokens.length; i++) {
    //     //     address payToken = payTokens[i];
    //     //     uint256 amount = amounts[i];
    //     //     _payTokenToPool(sender, payToken, amount);
    //     //     if (payToken != self.pool.token) {
    //     //         amount *= self.assets[payToken].conversion; // Convert to canonical
    //     //         _updateAssetBalance(payToken, amount, 0);
    //     //     }
    //     // }

    //     // // Transfer tokens to the receiving address
    //     // for (uint256 i; i < receiveTokens.length; i++) {
    //     //     address receiveToken = receiveTokens[i];
    //     //     uint256 receiveAmount = receiveAmounts[i];
    //     //     _payTokenToSender(sender, receiveToken, receiveAmount);
    //     //     if (receiveToken != self.pool.token) {
    //     //         receiveAmount *= self.assets[receiveToken].conversion; // Convert to canonical
    //     //         _updateAssetBalance(receiveToken, 0, receiveAmount);
    //     //     }
    //     // }

    //     // // Distribute fee
    //     // distributeFee(feeAmount);

    //     // // Update pool balance
    //     // _updatePoolBalance();
    // }

    // function multiswap(
    //     address[] memory payTokens,
    //     uint256[] memory amounts,
    //     address[] memory receiveTokens,
    //     uint256[] memory allocations,
    //     uint256[] memory minReceiveAmounts
    // )
    //     public
    //     payable
    //     // onlyInitialized
    //     returns (uint256[] memory receiveAmounts, uint256 feeAmount)
    // {
    //     // if (_tradingPaused) revert TradingPausedError();

    //     // address sender = _msgSender();
    //     // // Check user
    //     // {
    //     //     _checkUser(sender);
    //     // }
    //     // // Check lengths
    //     // {
    //     //     if (payTokens.length == 0) revert ZeroLength();
    //     //     if (receiveTokens.length == 0) revert ZeroLength();
    //     //     if (payTokens.length != amounts.length)
    //     //         revert LengthMismatch(payTokens.length, amounts.length);
    //     //     if (receiveTokens.length != allocations.length)
    //     //         revert LengthMismatch(receiveTokens.length, allocations.length);
    //     //     if (receiveTokens.length != minReceiveAmounts.length)
    //     //         revert LengthMismatch(
    //     //             receiveTokens.length,
    //     //             minReceiveAmounts.length
    //     //         );
    //     // }
    //     // // Check duplicates
    //     // {
    //     //     bool isLP;
    //     //     bool[] memory check_ = new bool[](self.assetAddresses.length);
    //     //     isLP = _checkDuplicateTokens(payTokens, check_, isLP);
    //     //     isLP = _checkDuplicateTokens(receiveTokens, check_, isLP);
    //     // }
    //     // // Check amounts
    //     // {
    //     //     for (uint256 i; i < amounts.length; i++) {
    //     //         if (amounts[i] == 0) revert ZeroAmount();
    //     //     }
    //     // }
    //     // // Check allocations
    //     // {
    //     //     uint256 totalAllocation;
    //     //     for (uint256 i; i < allocations.length; i++) {
    //     //         if (allocations[i] == 0) revert ZeroAllocation();
    //     //         totalAllocation += allocations[i];
    //     //     }
    //     //     if (totalAllocation != 1e18)
    //     //         revert IncorrectAmount(1e18, totalAllocation);
    //     // }
    //     // // Check size
    //     // {
    //     //     for (uint256 i; i < payTokens.length; i++) {
    //     //         address payToken = payTokens[i];
    //     //         uint256 balance_;
    //     //         if (payToken == self.pool.token) {
    //     //             balance_ = self.pool.balance;
    //     //         } else {
    //     //             balance_ =
    //     //                 self.assets[payToken].balance /
    //     //                 self.assets[payToken].conversion; // Convert from canonical
    //     //         }
    //     //         if (amounts[i] * 3 > balance_) revert TooLarge(amounts[i]);
    //     //     }
    //     // }

    //     // (receiveAmounts, feeAmount) = _multiswap(
    //     //     sender,
    //     //     payTokens,
    //     //     amounts,
    //     //     receiveTokens,
    //     //     allocations,
    //     //     minReceiveAmounts
    //     // );

    //     // emit Multiswap(
    //     //     _txCount,
    //     //     sender,
    //     //     payTokens,
    //     //     receiveTokens,
    //     //     amounts,
    //     //     receiveAmounts,
    //     //     feeAmount
    //     // );
    // }

    // function swap(
    //     address payToken,
    //     address receiveToken,
    //     uint256 payAmount,
    //     uint256 minReceiveAmount
    // )
    //     public
    //     payable
    //     // onlyInitialized
    //     returns (uint256 receiveAmount, uint256 feeAmount)
    // {
    //     // if (_tradingPaused) revert TradingPausedError();
    //     // address sender = _msgSender();
    //     // _checkUser(sender);
    //     // if (payToken == self.pool.token)
    //     //     revert InvalidSwap(payToken, receiveToken);
    //     // if (receiveToken == self.pool.token)
    //     //     revert InvalidSwap(payToken, receiveToken);
    //     // if (payToken == receiveToken) revert DuplicateToken(payToken);
    //     // if (self.assets[payToken].decimals == 0) revert AssetNotFound(payToken);
    //     // if (self.assets[receiveToken].decimals == 0)
    //     //     revert AssetNotFound(receiveToken);
    //     // if (payAmount == 0) revert ZeroAmount();
    //     // if (
    //     //     payAmount * 3 >
    //     //     self.assets[payToken].balance / self.assets[payToken].conversion
    //     // ) revert TooLarge(payAmount);

    //     // {
    //     //     address[] memory payTokens = new address[](1);
    //     //     uint256[] memory amounts = new uint256[](1);
    //     //     address[] memory receiveTokens = new address[](1);
    //     //     uint256[] memory allocations = new uint256[](1);
    //     //     uint256[] memory minReceiveAmounts = new uint256[](1);
    //     //     uint256[] memory receiveAmounts = new uint256[](1);

    //     //     payTokens[0] = payToken;
    //     //     amounts[0] = payAmount;
    //     //     receiveTokens[0] = receiveToken;
    //     //     allocations[0] = 1e18;
    //     //     minReceiveAmounts[0] = minReceiveAmount;

    //     //     (receiveAmounts, feeAmount) = _multiswap(
    //     //         sender,
    //     //         payTokens,
    //     //         amounts,
    //     //         receiveTokens,
    //     //         allocations,
    //     //         minReceiveAmounts
    //     //     );

    //     //     receiveAmount = receiveAmounts[0];
    //     // }

    //     // emit Swap(
    //     //     _txCount,
    //     //     sender,
    //     //     payToken,
    //     //     receiveToken,
    //     //     payAmount,
    //     //     receiveAmount,
    //     //     feeAmount
    //     // );
    // }

    // function stake(
    //     address payToken,
    //     uint256 payAmount,
    //     uint256 minReceiveAmount
    // )
    //     public
    //     payable
    //     // onlyInitialized
    //     returns (uint256 receiveAmount, uint256 feeAmount)
    // {
    //     // if (_tradingPaused) revert TradingPausedError();
    //     // address sender = _msgSender();
    //     // _checkUser(sender);
    //     // if (payToken == self.pool.token) revert InvalidStake(payToken);
    //     // if (self.assets[payToken].decimals == 0) revert AssetNotFound(payToken);
    //     // if (payAmount == 0) revert ZeroAmount();
    //     // if (
    //     //     payAmount * 3 >
    //     //     self.assets[payToken].balance / self.assets[payToken].conversion
    //     // ) revert TooLarge(payAmount);

    //     // {
    //     //     address[] memory payTokens = new address[](1);
    //     //     uint256[] memory amounts = new uint256[](1);
    //     //     address[] memory receiveTokens = new address[](1);
    //     //     uint256[] memory allocations = new uint256[](1);
    //     //     uint256[] memory minReceiveAmounts = new uint256[](1);
    //     //     uint256[] memory receiveAmounts = new uint256[](1);

    //     //     payTokens[0] = payToken;
    //     //     amounts[0] = payAmount;
    //     //     receiveTokens[0] = self.pool.token;
    //     //     allocations[0] = 1e18;
    //     //     minReceiveAmounts[0] = minReceiveAmount;

    //     //     (receiveAmounts, feeAmount) = _multiswap(
    //     //         sender,
    //     //         payTokens,
    //     //         amounts,
    //     //         receiveTokens,
    //     //         allocations,
    //     //         minReceiveAmounts
    //     //     );

    //     //     receiveAmount = receiveAmounts[0];
    //     // }

    //     // emit Stake(_txCount, sender, payToken, payAmount, receiveAmount);
    // }

    // function unstake(
    //     address receiveToken,
    //     uint256 payAmount,
    //     uint256 minReceiveAmount
    // )
    //     public
    //     // onlyInitialized
    //     returns (uint256 receiveAmount, uint256 feeAmount)
    // {
    //     // if (_tradingPaused) revert TradingPausedError();
    //     // address sender = _msgSender();
    //     // _checkUser(sender);
    //     // if (receiveToken == self.pool.token) revert InvalidUnstake(receiveToken);
    //     // if (self.assets[receiveToken].decimals == 0)
    //     //     revert AssetNotFound(receiveToken);
    //     // if (payAmount == 0) revert ZeroAmount();
    //     // if (payAmount * 3 > self.pool.balance) revert TooLarge(payAmount);

    //     // address[] memory payTokens = new address[](1);
    //     // uint256[] memory amounts = new uint256[](1);
    //     // address[] memory receiveTokens = new address[](1);
    //     // uint256[] memory allocations = new uint256[](1);
    //     // uint256[] memory minReceiveAmounts = new uint256[](1);
    //     // uint256[] memory receiveAmounts = new uint256[](1);

    //     // payTokens[0] = self.pool.token;
    //     // amounts[0] = payAmount;
    //     // receiveTokens[0] = receiveToken;
    //     // allocations[0] = 1e18;
    //     // minReceiveAmounts[0] = minReceiveAmount;

    //     // (receiveAmounts, feeAmount) = _multiswap(
    //     //     sender,
    //     //     payTokens,
    //     //     amounts,
    //     //     receiveTokens,
    //     //     allocations,
    //     //     minReceiveAmounts
    //     // );

    //     // receiveAmount = receiveAmounts[0];

    //     // emit Unstake(
    //     //     _txCount,
    //     //     sender,
    //     //     receiveToken,
    //     //     payAmount,
    //     //     receiveAmount,
    //     //     feeAmount
    //     // );
    // }

    // function addLiquidity(
    //     address token,
    //     uint256 amount,
    //     uint256[] memory maxPayAmounts
    // )
    //     public
    //     payable
    //     // onlyInitialized
    //     nonReentrant
    //     returns (uint256[] memory payAmounts)
    // {
    //     // if (_tradingPaused) revert TradingPausedError();
    //     // if (self.assetAddresses.length != maxPayAmounts.length)
    //     //     revert LengthMismatch(self.assetAddresses.length, maxPayAmounts.length);
    //     // if (amount == 0) revert ZeroAmount();
    //     // address sender = _msgSender();
    //     // _checkUser(sender);

    //     // _txCount++;

    //     // AssetState storage assetIn;
    //     // payAmounts = new uint256[](self.assetAddresses.length);

    //     // uint256 g;
    //     // if (token == self.pool.token) {
    //     //     g = (self.pool.balance +
    //     //         amount.mulWadUp(self.pool.tokensPerShare)).divWadUp(
    //     //             self.pool.balance
    //     //         );
    //     // } else {
    //     //     assetIn = self.assets[token];
    //     //     if (assetIn.decimals == 0) revert AssetNotFound(token);
    //     //     g = (assetIn.balance + amount * assetIn.conversion).divWadUp(
    //     //         assetIn.balance
    //     //     );
    //     // }
    //     // address payAddress;
    //     // uint256 payAmount;
    //     // for (uint256 i; i < self.assetAddresses.length; i++) {
    //     //     assetIn = self.assets[self.assetAddresses[i]];
    //     //     if (
    //     //         (assetIn.token == token) ||
    //     //         (assetIn.token == _wrappedNativeAddress && token == address(0))
    //     //     ) {
    //     //         payAddress = token;
    //     //         payAmount = amount;
    //     //     } else {
    //     //         payAddress = self.assetAddresses[i];
    //     //         payAmount =
    //     //             (assetIn.balance.mulWadUp(g) - assetIn.balance) /
    //     //             assetIn.conversion;
    //     //     }
    //     //     if (payAmount > maxPayAmounts[i])
    //     //         revert ExcessivePayAmount(maxPayAmounts[i], payAmount);
    //     //     payAmounts[i] = payAmount;

    //     //     _payTokenToPool(sender, payAddress, payAmount);
    //     //     payAmount *= assetIn.conversion; // Convert to canonical
    //     //     _updateAssetBalance(self.assetAddresses[i], payAmount, 0);
    //     // }

    //     // _mint(sender, amount);
    //     // _updatePoolBalance();

    //     // emit AddLiquidity(_txCount, sender, payAmounts, amount);
    // }

    // function _removeLiquidity(
    //     address sender,
    //     uint256 amount,
    //     uint256[] memory minReceiveAmounts
    // ) private returns (uint256[] memory receiveAmounts, uint256 feeAmount) {
    //     // uint256 n = self.assetAddresses.length;
    //     // address[] memory payTokens = new address[](1);
    //     // uint256[] memory amounts = new uint256[](1);
    //     // address[] memory receiveTokens = new address[](n);
    //     // uint256[] memory allocations = new uint256[](n);
    //     // receiveAmounts = new uint256[](n);

    //     // payTokens[0] = self.pool.token;
    //     // amounts[0] = amount;
    //     // receiveTokens = self.assetAddresses;
    //     // {
    //     //     uint256 allocation;
    //     //     uint256 totalAllocation;
    //     //     for (uint256 i; i < n - 1; i++) {
    //     //         allocation = self.assets[self.assetAddresses[i]].scale.divWadUp(
    //     //             self.pool.scale
    //     //         );
    //     //         allocations[i] = allocation;
    //     //         totalAllocation += allocation;
    //     //     }
    //     //     allocations[n - 1] = 1e18 - totalAllocation;
    //     // }

    //     // (receiveAmounts, feeAmount) = _multiswap(
    //     //     sender,
    //     //     payTokens,
    //     //     amounts,
    //     //     receiveTokens,
    //     //     allocations,
    //     //     minReceiveAmounts
    //     // );

    //     // emit RemoveLiquidity(
    //     //     _txCount,
    //     //     sender,
    //     //     amount,
    //     //     receiveAmounts,
    //     //     feeAmount
    //     // );
    // }

    // function removeLiquidity(
    //     uint256 amount,
    //     uint256[] memory minReceiveAmounts
    // )
    //     public
    //     // onlyInitialized
    //     returns (uint256[] memory receiveAmounts, uint256 feeAmount)
    // {
    //     // if (self.assetAddresses.length != minReceiveAmounts.length)
    //     //     revert LengthMismatch(
    //     //         self.assetAddresses.length,
    //     //         minReceiveAmounts.length
    //     //     );
    //     // if (amount == 0) revert ZeroAmount();
    //     // (receiveAmounts, feeAmount) = _removeLiquidity(
    //     //     _msgSender(),
    //     //     amount,
    //     //     minReceiveAmounts
    //     // );
    // }
}
