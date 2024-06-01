// SPDX-License-Identifier: Business Source License 1.1
// Copyright (C) 2020-2023, CavalRe Inc. All rights reserved.
// See the file LICENSE.md for licensing terms.
pragma solidity 0.8.24;

import {ILPToken} from "./ILPToken.sol";

struct PoolState {
    address token;
    string name;
    string symbol;
    uint8 decimals;
    int256 omega;
    uint256 tokensPerShare; // LP token price per share
    uint256 balance; // # of LP tokens
    uint256 scale;
    uint256 lastUpdated;
}

struct AssetState {
    address token;
    uint256 index;
    string name;
    string symbol;
    uint8 decimals;
    uint256 conversion;
    uint256 fee;
    uint256 balance;
    uint256 scale;
    uint256 lastUpdated;
}

struct State {
    PoolState pool;
    mapping(address => AssetState) assets;
    address[] assetAddresses;
    mapping(address => uint256) discount;
}

struct Order {
    address token;
    uint256 amount;
}

interface IPool is ILPToken {
    event AssetAdded(
        address indexed token,
        uint256 fee,
        uint256 balance,
        uint256 scale
    );

    event AssetRemoved(address indexed token);

    event Initialized(address indexed poolAddress);

    event BalanceUpdate(
        uint256 indexed txCount,
        address indexed token,
        uint256 balance
    );

    event Multiswap(
        uint256 indexed txCount,
        address indexed user,
        address[] payTokens,
        address[] receiveTokens,
        uint256[] payAmounts,
        uint256[] receiveAmounts,
        uint256 feeAmount
    );

    event Swap(
        uint256 indexed txCount,
        address indexed user,
        address payToken,
        address receiveToken,
        uint256 payAmount,
        uint256 receiveAmount,
        uint256 feeAmount
    );

    event Stake(
        uint256 indexed txCount,
        address indexed user,
        address payToken,
        uint256 payAmount,
        uint256 receiveAmount
    );

    event Unstake(
        uint256 indexed txCount,
        address indexed user,
        address receiveToken,
        uint256 payAmount,
        uint256 receiveAmount,
        uint256 feeAmount
    );

    event AddLiquidity(
        uint256 indexed txCount,
        address indexed user,
        uint256[] payAmounts,
        uint256 receiveAmount
    );

    event RemoveLiquidity(
        uint256 indexed txCount,
        address indexed user,
        uint256 payAmount,
        uint256[] receiveAmounts,
        uint256 feeAmount
    );

    event UserBlocked(address indexed user);

    event UserBlockLifted(address indexed user);

    event TradingPaused();

    event TradingResumed();

    event PoolDisabled(uint256 indexed txCount, address indexed poolAddress);

    error AlreadyInitialized();

    error AssetNotFound(address asset);

    error DuplicateToken(address payToken);

    error ExcessivePayAmount(uint256 expected, uint256 actual);

    error IncorrectAmount(uint256 expected, uint256 actual);

    error IncorrectDecimals(uint256 expected, uint256 actual);

    error InsufficientReceiveAmount(uint256 expected, uint256 actual);

    error InvalidStake(address payToken);

    error InvalidSwap(address payToken, address receiveToken);

    error InvalidUnstake(address receiveToken);

    error InvariantViolation(uint256 valueIn, uint256 valueOut);

    error LengthMismatch(uint256 expected, uint256 actual);

    error LPTokenFirst();

    error NotInitialized();

    error TooLarge(uint256 size);

    error TooSmall(uint256 size);

    error TradingPausedError();

    error ZeroAllocation();

    error ZeroAmount();

    error ZeroBalance();

    error ZeroLength();

    error ZeroScale();

    function addAsset(
        address token_,
        uint256 fee_, // 18 decimals
        uint256 balance_, // Token decimals
        uint256 scale_ // 18 decimals
    ) external payable;

    function removeAsset(address token) external;

    function setTau(uint256 tau) external;

    function initialize() external;

    function txCount() external view returns (uint256);

    function isInitialized() external view returns (bool);

    function info() external view returns (PoolState memory);

    function assets() external view returns (AssetState[] memory);

    function assetAddresses() external view returns (address[] memory);

    function asset(address token) external view returns (AssetState memory);

    function isPaused() external view returns (bool);

    // function _quoteMultiswap(
    //     address sender,
    //     address[] memory payTokens,
    //     uint256[] memory amounts,
    //     address[] memory receiveTokens,
    //     uint256[] memory allocations
    // )
    //     external
    //     view
    //     returns (uint256[] memory receiveAmounts, uint256 feeAmount);

    // function quoteMultiswap(
    //     address[] memory payTokens,
    //     uint256[] memory amounts,
    //     address[] memory receiveTokens,
    //     uint256[] memory allocations
    // )
    //     external
    //     view
    //     returns (uint256[] memory receiveAmounts, uint256 feeAmount);

    // function multiswap(
    //     address[] memory payTokens,
    //     uint256[] memory amounts,
    //     address[] memory receiveTokens,
    //     uint256[] memory allocations,
    //     uint256[] memory minReceiveAmounts
    // )
    //     external
    //     payable
    //     returns (uint256[] memory receiveAmounts, uint256 feeAmount);

    // function quoteSwap(
    //     address payToken,
    //     address receiveToken,
    //     uint256 payAmount
    // ) external returns (uint256 receiveAmount, uint256 feeAmount);

    // function swap(
    //     address payToken,
    //     address receiveToken,
    //     uint256 payAmount,
    //     uint256 minReceiveAmount
    // ) external payable returns (uint256 receiveAmount, uint256 feeAmount);

    // function quoteStake(
    //     address payToken,
    //     uint256 payAmount
    // ) external returns (uint256 receiveAmount, uint256 feeAmount);

    // function stake(
    //     address payToken,
    //     uint256 payAmount,
    //     uint256 minReceiveAmount
    // ) external payable returns (uint256 receiveAmount, uint256 feeAmount);

    // function quoteUnstake(
    //     address receiveToken,
    //     uint256 payAmount
    // ) external returns (uint256 receiveAmount, uint256 feeAmount);

    // function unstake(
    //     address receiveToken,
    //     uint256 payAmount,
    //     uint256 minReceiveAmount
    // ) external returns (uint256 receiveAmount, uint256 feeAmount);

    // function quoteAddLiquidity(
    //     address token,
    //     uint256 amount
    // ) external returns (uint256[] memory payAmounts);

    // function addLiquidity(
    //     address token,
    //     uint256 amount,
    //     uint256[] memory maxPayAmounts
    // ) external payable returns (uint256[] memory payAmounts);

    // function quoteRemoveLiquidity(
    //     uint256 amount
    // ) external returns (uint256[] memory receiveAmounts, uint256 feeAmount);

    // function removeLiquidity(
    //     uint256 amount,
    //     uint256[] memory minReceiveAmounts
    // ) external returns (uint256[] memory receiveAmounts, uint256 feeAmount);

    function setIsAllowed(address user_, bool isAllowed_) external;

    function pauseTrading() external;

    function resumeTrading() external;
}
