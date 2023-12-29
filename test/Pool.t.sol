// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {Pool} from "../contracts/Pool.sol";
import {PoolState, AssetState, QuoteState} from "../contracts/interfaces/IPool.sol";
import {Token} from "./Token.t.sol";
import {FixedPointMathLib} from "../contracts/libraries/FixedPointMath/src/FixedPointMathLib.sol";
import {Test, stdMath} from "forge-std/Test.sol";

contract PoolTest is Test {
    using FixedPointMathLib for uint256;
    using stdMath for uint256;

    uint256 internal constant NTOKENS = 10;

    address internal alice = address(1);
    address internal bob = address(2);
    address internal carol = address(3);

    // uint256 internal constant INTERNAL_DECIMALS = 27;
    // uint256 internal constant ONE = 10 ** INTERNAL_DECIMALS;
    // uint256 internal constant PCT = 10 ** (INTERNAL_DECIMALS - 2);
    // uint256 internal constant BPS = 10 ** (INTERNAL_DECIMALS - 4);
    uint256 internal constant ONE = 10 ** 18; // 18 decimals
    uint256 internal constant PCT = 10 ** 16; // 18 decimals
    uint256 internal constant BPS = 10 ** 14; // 18 decimals
    uint256 internal constant HALF = 5 * 10 ** 17;

    address internal protocolFeeRecipient = address(4);
    uint256 internal initialTokensPerShare = 3e18; // 18 decimals

    uint256[] internal balances = new uint256[](NTOKENS);
    uint256[] internal fees = new uint256[](NTOKENS);
    uint256[] internal prices = new uint256[](NTOKENS);
    uint256[] internal conversions = new uint256[](NTOKENS);

    uint256 internal marketCap = 1e25;

    Token internal WAVAX = new Token("Wrapped AVAX", "WAVAX", 18);
    Token internal USDC = new Token("USD Coin", "USDC", 6);
    Token internal USDt = new Token("TetherToken", "USDt", 6);
    Token internal EUROC = new Token("Euro Coin", "EUROC", 6);
    Token internal USDCe = new Token("Bridged USDC", "USDC.e", 6);
    Token internal USDTe = new Token("Bridged USDt", "USDT.e", 6);
    Token internal DAIe = new Token("Brdiged DAI", "DAI.e", 18);
    Token internal WETHe = new Token("Bridged WETH", "WETH.e", 18);
    Token internal WBTCe = new Token("Bridged WBTC", "WBTC.e", 8);
    Token internal BTCb = new Token("Bridged BTC", "BTC.b", 8);

    function setUpPool(
        string memory name_,
        string memory symbol_,
        uint256 protocolFee_, // 18 decimals
        uint tau_ // 18 decimals
    ) public returns (Pool pool, Token[] memory tokens) {
        pool = new Pool(
            name_,
            symbol_,
            protocolFee_, // 18 decimals
            protocolFeeRecipient,
            initialTokensPerShare, // 18 decimals
            tau_, // 18 decimals
            address(WAVAX)
        );
        tokens = new Token[](NTOKENS);

        tokens[0] = WAVAX;
        tokens[1] = USDC;
        tokens[2] = USDt;
        tokens[3] = EUROC;
        tokens[4] = USDCe;
        tokens[5] = USDTe;
        tokens[6] = DAIe;
        tokens[7] = WETHe;
        tokens[8] = WBTCe;
        tokens[9] = BTCb;

        fees[0] = 15 * BPS;
        fees[1] = 5 * BPS;
        fees[2] = 5 * BPS;
        fees[3] = 5 * BPS;
        fees[4] = 5 * BPS;
        fees[5] = 5 * BPS;
        fees[6] = 5 * BPS;
        fees[7] = 30 * BPS;
        fees[8] = 30 * BPS;
        fees[9] = 30 * BPS;

        prices[0] = 145e17;
        prices[1] = 1e18;
        prices[2] = 1e18;
        prices[3] = 113e16;
        prices[4] = 1e18;
        prices[5] = 1e18;
        prices[6] = 1e18;
        prices[7] = 1908e18;
        prices[8] = 30065e18;
        prices[9] = 30065e18;

        balances[0] = 689655172413793000000000;
        balances[1] = 10000000000000;
        balances[2] = 10000000000000;
        balances[3] = 8849557522124;
        balances[4] = 10000000000000;
        balances[5] = 10000000000000;
        balances[6] = 10000000000000;
        balances[7] = 5241090146750520000000;
        balances[8] = 33261267254;
        balances[9] = 33261267254;

        Token token;
        uint256 conversion;
        for (uint256 i; i < NTOKENS; i++) {
            token = tokens[i];
            conversion = 10 ** (18 - token.decimals());
            conversions[i] = conversion;
            if (address(token) == address(WAVAX)) {
                vm.deal(address(token), balances[i]);
            }
            token.mint(balances[i]);
            token.approve(address(pool), balances[i]);
            pool.addAsset(address(token), fees[i], balances[i], marketCap);
        }

        pool.initialize();

        for (uint256 i; i < NTOKENS; i++) {
            token = tokens[i];
            if (address(token) == address(WAVAX)) {
                vm.deal(address(token), balances[i]);
            }
            token.mint(balances[i]);
            token.approve(address(pool), balances[i]);
        }
    }

    function digits(uint256 number_) public pure returns (uint8) {
        if (number_ == 0) {
            return 1; // Zero has 1 significant digit
        }

        uint8 count = 0;
        while (number_ != 0) {
            count++;
            number_ /= 10; // Remove the least significant digit
        }
        return count;
    }

    function symbol(
        Pool pool,
        address token
    ) public view returns (string memory) {
        if (token == address(pool)) return pool._info().symbol;
        return pool._asset(token).symbol;
    }

    function weight(
        Pool pool,
        address token
    )
        public
        view
        returns (
            uint256 // Internal decimals
        )
    {
        uint256 ONE_ = 10 ** pool._info().internalDecimals;
        return pool._asset(token).scale.divUp(pool._info().scale, ONE_);
    }

    function scale(
        Pool pool,
        address token
    )
        public
        view
        returns (
            uint256 // Internal decimals
        )
    {
        if (token == address(pool)) return pool._info().scale;
        return pool._asset(token).scale;
    }

    function balance(
        Pool pool,
        address token
    )
        public
        view
        returns (
            uint256 // Internal decimals
        )
    {
        if (token == address(pool)) return pool._info().balance;
        return pool._asset(token).balance;
    }

    function price(
        Pool pool,
        address token,
        address numeraire
    )
        public
        view
        returns (
            uint256 // Internal decimals
        )
    {
        uint256 scaleToken = scale(pool, token);
        uint256 scaleNumeraire = scale(pool, numeraire);
        uint256 balanceToken = balance(pool, token);
        uint256 balanceNumeraire = balance(pool, numeraire);
        uint256 ONE_ = 10 ** pool._info().internalDecimals;
        return
            scaleToken.fullMulDiv(
                balanceNumeraire,
                scaleNumeraire.mulUp(balanceToken, ONE_)
            );
    }

    function fee(
        Pool pool,
        address token
    )
        public
        view
        returns (
            uint256 // Internal decimals
        )
    {
        if (token == address(pool)) return 0;
        return pool._asset(token).fee;
    }

    function scaledValueIn(
        Pool pool,
        QuoteState memory q
    )
        public
        view
        returns (
            uint256 // Internal decimals
        )
    {
        uint256 scale_;
        uint256 amount_;
        uint256 poolIn_;
        uint256 finalBalance_;
        uint256 scaledValueIn_;
        uint256 ONE_ = 10 ** pool._info().internalDecimals;
        for (uint256 i; i < q.payTokens.length; i++) {
            address payToken = q.payTokens[i];
            amount_ = q.payAmounts[i];
            if (payToken == address(pool)) {
                poolIn_ = amount_.mulUp(q.initialTokensPerShare, ONE_);
                continue;
            }
            scale_ = scale(pool, payToken); // Assumes scale does not change
            finalBalance_ = balance(pool, payToken) + amount_;
            scaledValueIn_ += scale_.fullMulDiv(amount_, finalBalance_);
        }
        if (poolIn_ > 0) {
            scaledValueIn_ += scale(pool, address(pool)).fullMulDiv(
                poolIn_,
                q.finalTokens
            );
        }
        return scaledValueIn_;
    }

    function scaledValueOut(
        Pool pool,
        QuoteState memory q
    ) public view returns (uint256) {
        uint256 scale_;
        uint256 amount_;
        uint256 finalBalance_;
        uint256 poolScale_;
        uint256 poolAmount_;
        uint256 scaledValueOut_;
        uint256 ONE_ = 10 ** pool._info().internalDecimals;
        for (uint256 i; i < q.receiveTokens.length; i++) {
            address receiveToken = q.receiveTokens[i];
            amount_ = q.receiveAmounts[i];
            if (receiveToken == address(pool)) {
                poolAmount_ = amount_.mulUp(q.finalTokensPerShare, ONE_);
                continue;
            }
            scale_ = scale(pool, receiveToken);
            finalBalance_ = balance(pool, receiveToken) - amount_;
            scaledValueOut_ += scale_.fullMulDiv(amount_, finalBalance_);
        }
        poolScale_ = scale(pool, address(pool));
        scaledValueOut_ += poolScale_.fullMulDiv(
            q.feeAmount + poolAmount_,
            q.finalTokens
        );
        return scaledValueOut_;
    }

    function showAsset(
        Pool pool,
        address token,
        address numeraire
    ) internal {
        AssetState memory asset = pool._asset(token);
        uint256 ONE_ = 10 ** pool._info().internalDecimals;
        emit log("-------");
        emit log_named_string("name", asset.name);
        uint256 price_ = price(pool, token, numeraire);
        emit log_named_decimal_uint("price", price_, pool._info().internalDecimals);
        emit log_named_decimal_uint("balance", asset.balance, pool._info().internalDecimals);
        emit log_named_decimal_uint("marketcap", price_.mulUp(asset.balance, ONE_), pool._info().internalDecimals);
        emit log_named_decimal_uint("scale", asset.scale, pool._info().internalDecimals);
        emit log_named_decimal_uint("fee", asset.fee, pool._info().internalDecimals);
    }

    function showPool(Pool _pool, address numeraire) internal {
        PoolState memory pool_;
        AssetState[] memory assetStates_;
        (pool_, assetStates_) = _pool._state();
        emit log("==================================================");
        emit log("Pool Info");
        // emit log("Name:",poolName);
        // emit log("Symbol:",poolSymbol);
        // emit log_named_uint("Decimals", poolDecimals);
        // emit log_named_uint("totalSupply", pool.totalSupply());
        emit log_named_decimal_uint("balance", pool_.balance, pool_.internalDecimals);
        emit log_named_decimal_uint("shares (18 decimals)", _pool.totalSupply(), 18);
        emit log_named_decimal_uint("scale", pool_.scale, pool_.internalDecimals);
        emit log("");
        emit log("Assets:");
        for (uint256 i; i < NTOKENS; i++) {
            showAsset(_pool, assetStates_[i].token, numeraire);
        }
    }

    function showQuote(Pool pool, QuoteState memory q) internal {
        // AssetState[] memory assetStates = pool.assets();
        emit log("==================================================");
        emit log("Quote");
        // emit log("");
        // emit log("---------");
        // emit log("Balances:");
        // emit log("---------");
        // emit log_named_uint(
        //     pool.symbol(),
        //     pool.info().balance
        // );
        // for (uint256 i; i < assetStates.length; i++) {
        //     AssetState memory asset_ = assetStates[i];
        //     emit log_named_uint(
        //         asset_.symbol,
        //         asset_.balance
        //     );
        // }
        emit log("");
        emit log("------------");
        emit log("Pay Amounts:");
        emit log("------------");
        uint256 ONE_ = 10 ** pool._info().internalDecimals;
        for (uint256 i; i < q.payTokens.length; i++) {
            if (q.payTokens[i] == address(pool)) {
                emit log_named_decimal_uint(
                    "LP Tokens",
                    q.payAmounts[i].mulUp(q.initialTokensPerShare, ONE),
                    pool._info().internalDecimals
                );
            } else {
                emit log_named_decimal_uint(
                    pool.asset(q.payTokens[i]).symbol,
                    q.payAmounts[i],
                    pool._info().internalDecimals
                );
            }
        }
        emit log("");
        emit log("----------------");
        emit log("Receive Amounts:");
        emit log("----------------");
        for (uint256 i; i < q.receiveTokens.length; i++) {
            if (q.receiveTokens[i] == address(pool)) {
                emit log_named_decimal_uint(
                    pool.symbol(),
                    q.receiveAmounts[i].mulUp(q.finalTokensPerShare, ONE_),
                    pool._info().internalDecimals
                );
            } else {
                emit log_named_decimal_uint(
                    pool.asset(q.receiveTokens[i]).symbol,
                    q.receiveAmounts[i],
                    pool._info().internalDecimals
                );
            }
        }
        emit log("");
        emit log("-----------");
        emit log("Fee Amount:");
        emit log("-----------");
        emit log_named_decimal_uint("Fee amount", q.feeAmount, pool._info().internalDecimals);
        emit log("");
        emit log("--------------");
        emit log("Miscellaneous:");
        emit log("--------------");
        emit log_named_decimal_uint("Multiplier", pool.conversion(address(pool)), pool._info().internalDecimals);
        emit log_named_decimal_uint("Initial tokens", q.initialTokens, pool._info().internalDecimals);
        emit log_named_decimal_uint("Initial shares", q.initialShares, pool._info().internalDecimals);
        emit log_named_decimal_uint(
            "Initial tokens per share",
            q.initialTokensPerShare,
            pool._info().internalDecimals
        );
        emit log_named_decimal_uint("Final tokens", q.finalTokens, pool._info().internalDecimals);
        emit log_named_decimal_uint("Final shares", q.finalShares, pool._info().internalDecimals);
        emit log_named_decimal_uint("Final tokens per share", q.finalTokensPerShare, pool._info().internalDecimals);
        emit log_named_decimal_uint("Fee", q.fee, pool._info().internalDecimals);
        emit log_named_decimal_uint("Discount", q.discount, pool._info().internalDecimals);
        emit log_named_decimal_uint("Pool allocation", q.poolAlloc, pool._info().internalDecimals);
        emit log_named_decimal_uint("Last pool balance", q.lastPoolBalance, pool._info().internalDecimals);
        emit log_named_decimal_uint("Scaled pool out", q.scaledPoolOut, pool._info().internalDecimals);
        emit log_named_decimal_uint("Shares in", q.sharesIn, pool._info().internalDecimals);
        emit log_named_decimal_uint("Pool in", q.poolIn, pool._info().internalDecimals);
        emit log_named_decimal_uint("Pool out", q.poolOut, pool._info().internalDecimals);
        emit log_named_decimal_uint("Scaled value in", q.scaledValueIn, pool._info().internalDecimals);
        emit log("");
    }

    struct ExcelComp {
        uint8 ndigits;
        uint256 conversion;
        uint8 decimals;
        uint256 amount;
    }

    function checkVsExcel(
        Pool pool,
        QuoteState memory q,
        // address[] memory payTokens,
        // uint256[] memory payAmounts, // Token decimals
        // address[] memory receiveTokens,
        // uint256[] memory allocations, // 18 decimals
        uint256[] memory checkPayAmounts, // Internal decimals
        uint256[] memory checkReceiveAmounts, // Internal decimals
        uint256 checkFeeAmount, // Internal decimals
        string memory message
    ) public {
        // QuoteState memory q = pool._quoteMultiswap(
        //     alice,
        //     payTokens,
        //     payAmounts,
        //     receiveTokens,
        //     allocations
        // );
        ExcelComp memory e;

        for (uint256 i; i < checkPayAmounts.length; i++) {
            e.decimals = pool._info().internalDecimals;
            e.amount = q.payAmounts[i];
            e.ndigits = digits(e.amount);
            if (e.ndigits > 15) {
                e.decimals -= e.ndigits - 15;
                e.conversion = 10 ** (e.ndigits - 15);
            } else {
                e.decimals -= 1;
                e.conversion = 10;
            }
            if (q.payTokens[i] == address(pool)) {
                e.amount = e.amount.mulUp(
                    q.initialTokensPerShare,
                    10 ** pool._info().internalDecimals
                );
            }
            // emit log("Check pay amount");
            assertApproxEqAbsDecimal(
                e.amount / e.conversion,
                checkPayAmounts[i] / e.conversion,
                1,
                e.decimals,
                symbol(pool, q.payTokens[i])
            );
        }

        for (uint256 i; i < checkReceiveAmounts.length; i++) {
            e.decimals = pool._info().internalDecimals;
            e.amount = q.receiveAmounts[i];
            e.ndigits = digits(e.amount);
            if (e.ndigits > 15) {
                e.decimals -= e.ndigits - 15;
                e.conversion = 10 ** (e.ndigits - 15);
            } else {
                e.decimals -= 1;
                e.conversion = 10;
            }
            if (q.receiveTokens[i] == address(pool)) {
                e.amount = e.amount.mulUp(
                    q.finalTokensPerShare,
                    10 ** pool._info().internalDecimals
                );
            }
            // emit log("Check receive amount");
            assertApproxEqAbsDecimal(
                e.amount / e.conversion,
                checkReceiveAmounts[i] / e.conversion,
                1,
                e.decimals,
                symbol(pool, q.receiveTokens[i])
            );
        }
        e.ndigits = digits(q.feeAmount);
        e.decimals = pool._info().internalDecimals;
        if (e.ndigits > 15) {
            e.decimals -= e.ndigits - 15;
            e.conversion = 10 ** (e.ndigits - 15);
        } else {
            e.decimals -= 1;
            e.conversion = 10;
        }
        assertApproxEqAbsDecimal(
            q.feeAmount / e.conversion,
            checkFeeAmount / e.conversion,
            1,
            e.decimals,
            "fee"
        );

        if (failed) {
            emit log(message);
            showQuote(pool, q);
        }
    }

    function checkSelfFinancing(
        Pool pool,
        QuoteState memory q,
        // address[] memory payTokens,
        // uint256[] memory payAmounts, // Token decimals
        // address[] memory receiveTokens,
        // uint256[] memory allocations, // 18 decimals
        string memory message
    ) public {
        // // showPool(pool, address(USDC));
        // // emit log("Check swap");
        // AssetState[] memory assetStates = pool.assets();
        // uint256[] memory minReceiveAmounts = new uint256[](
        //     receiveTokens.length
        // );

        // uint256 multiplier = pool.conversion(address(pool));

        // CompareState memory c;
        // c.initialTokens = pool.totalTokens();
        // c.initialShares = pool.totalSupply();
        // c.initialTokensPerShare = pool.tokensPerShare();
        // c.initialBalances = getBalances(pool);
        // c.initialScales = getScales(pool);
        // // emit log("Get quote");
        // // showPool(pool, address(USDC));
        // QuoteState memory q = pool._quoteMultiswap(
        //     alice,
        //     payTokens,
        //     payAmounts,
        //     receiveTokens,
        //     allocations
        // );
        uint8 ndigits;
        uint8 decimals_;
        uint256 conversion;
        ndigits = digits(q.scaledValueIn);
        decimals_ = pool._info().internalDecimals;
        if (ndigits > 15) {
            decimals_ -= ndigits - 15;
            conversion = 10 ** (ndigits - 15);
        } else {
            decimals_ -= 5;
            conversion = 1e5;
        }
        // assertApproxEqAbsDecimal(
        //     q.scaledValueIn / conversion,
        //     scaledValueIn(pool, q) / conversion,
        //     1,
        //     decimals_,
        //     "scaledValueIn"
        // );
        assertApproxEqAbsDecimal(
            scaledValueIn(pool, q) / conversion,
            scaledValueOut(pool, q) / conversion,
            1,
            decimals_,
            "Scaled value"
        );

        // // emit log("Execute swap");
        // (receiveAmounts, feeAmount) = pool.multiswap(
        //     payTokens,
        //     amounts,
        //     receiveTokens,
        //     allocations,
        //     minReceiveAmounts
        // );
        // // emit log("Swap executed");
        // c.finalTokens = pool.totalTokens();
        // c.finalShares = pool.totalSupply();
        // c.finalTokensPerShare = pool.tokensPerShare();
        // c.finalBalances = getBalances(pool);
        // c.finalScales = getScales(pool);
        // c.balanceIncrease = new uint256[](assetStates.length + 1);
        // c.balanceDecrease = new uint256[](assetStates.length + 1);

        // emit log("Show quote");
        if (failed) {
            emit log(message);
            showQuote(pool, q);
        }

        // {
        //     // emit log("Check quote");
        //     uint256 initialTokens = q.initialTokens / multiplier;
        //     if (c.initialTokens != initialTokens) {
        //         emit log("=======================");
        //         emit log("Initial tokens mismatch");
        //         emit log("=======================");
        //         emit log_named_uint("Initial tokens         ", c.initialTokens);
        //         emit log_named_uint("Initial tokens (quote) ", initialTokens);
        //         emit log("-----------------------");
        //         emit log_named_uint(
        //             "Delta                  ",
        //             delta(c.initialTokens, initialTokens)
        //         );
        //         fail();
        //     }
        //     uint256 finalTokens = q.finalTokens / multiplier;
        //     if (c.finalTokens != finalTokens) {
        //         emit log("=====================");
        //         emit log("Final tokens mismatch");
        //         emit log("=====================");
        //         emit log_named_uint("Final tokens        ", c.finalTokens);
        //         emit log_named_uint("Final tokens (quote)", finalTokens);
        //         emit log("---------------------");
        //         emit log_named_uint(
        //             "Delta                ",
        //             delta(c.finalTokens, q.finalTokens)
        //         );
        //         emit log_named_uint(
        //             "Increase             ",
        //             delta(c.finalTokens, c.initialTokens)
        //         );
        //         emit log_named_uint(
        //             "Increase (quote)     ",
        //             delta(q.finalTokens, q.initialTokens)
        //         );
        //         fail();
        //     }
        //     uint256 initialShares = q.initialShares / multiplier;
        //     if (c.initialShares != initialShares) {
        //         emit log("=======================");
        //         emit log("Initial shares mismatch");
        //         emit log("=======================");
        //         emit log_named_uint("Initial shares         ", c.initialShares);
        //         emit log_named_uint("Initial shares (quote) ", initialShares);
        //         emit log("-----------------------");
        //         emit log_named_uint(
        //             "Delta                  ",
        //             delta(c.initialShares, initialShares)
        //         );
        //         fail();
        //     }

        //     uint256 finalShares = q.finalShares / multiplier;
        //     if (c.finalShares != finalShares) {
        //         emit log("=====================");
        //         emit log("Final shares mismatch");
        //         emit log("=====================");
        //         emit log_named_uint("Final shares         ", c.finalShares);
        //         emit log_named_uint("Final shares (quote) ", finalShares);
        //         emit log("---------------------");
        //         emit log_named_uint(
        //             "Delta                ",
        //             delta(c.finalShares, finalShares)
        //         );
        //         emit log_named_uint(
        //             "Increase             ",
        //             delta(c.finalShares, initialShares)
        //         );
        //         emit log_named_uint(
        //             "Increase (quote)     ",
        //             delta(q.finalShares, initialShares)
        //         );
        //         fail();
        //     }
        //     uint256 initialTokensPerShare = q.initialTokensPerShare /
        //         multiplier;
        //     if (c.initialTokensPerShare != initialTokensPerShare) {
        //         emit log("=================================");
        //         emit log("Initial tokens per share mismatch");
        //         emit log("=================================");
        //         emit log_named_uint(
        //             "Initial tokens per share         ",
        //             c.initialTokensPerShare
        //         );
        //         emit log_named_uint(
        //             "Initial tokens per share (quote) ",
        //             initialTokensPerShare
        //         );
        //         emit log("---------------------------------");
        //         emit log_named_uint(
        //             "Delta                            ",
        //             delta(c.initialTokensPerShare, initialTokensPerShare)
        //         );
        //         fail();
        //     }
        //     uint256 finalTokensPerShare = q.finalTokensPerShare / multiplier;
        //     if (c.finalTokensPerShare != finalTokensPerShare) {
        //         emit log("===============================");
        //         emit log("Final tokens per share mismatch");
        //         emit log("===============================");
        //         emit log_named_uint(
        //             "Final tokens per share         ",
        //             c.finalTokensPerShare
        //         );
        //         emit log_named_uint(
        //             "Final tokens per share (quote) ",
        //             finalTokensPerShare
        //         );
        //         emit log("-------------------------------");
        //         emit log_named_uint(
        //             "Delta                          ",
        //             delta(c.finalTokensPerShare, finalTokensPerShare)
        //         );
        //         fail();
        //     }
        // }
    }

    // function blah() private {
    //     // {
    //     //     //Handle pool balances
    //     //     // emit log("Handle pool balances");
    //     //     c.balanceIncrease[0] += feeAmount * pool.multiplier();
    //     //     if (payTokens[0] == address(pool)) {
    //     //         c.balanceDecrease[0] += amounts[0].mulWadUp(
    //     //             c.initialTokensPerShare
    //     //         );
    //     //     }
    //     //     if (receiveTokens[0] == address(pool)) {
    //     //         c.balanceIncrease[0] += receiveAmounts[0].mulWadUp(
    //     //             c.finalTokensPerShare
    //     //         ); // RIGHT!
    //     //         // balanceIncrease[0] += receiveAmounts[0].mulWadUp(c.initialTokensPerShare); // WRONG!
    //     //     }
    //     //     // emit log_named_uint(
    //     //     //     "Initial pool balance",
    //     //     //     c.initialBalances[0]
    //     //     // );
    //     //     // emit log_named_uint("Fee amount", feeAmount);
    //     //     // emit log_named_uint("Balance increase", c.balanceIncrease[0]);
    //     //     // emit log_named_uint("Balance decrease", c.balanceDecrease[0]);
    //     //     // emit log_named_uint(
    //     //     //     "Final pool balance",
    //     //     //     c.finalBalances[0]
    //     //     // );
    //     //     // emit log("Check pool balance");
    //     //     assertEq(
    //     //         c.initialBalances[0] +
    //     //             c.balanceIncrease[0] -
    //     //             c.balanceDecrease[0],
    //     //         c.finalBalances[0],
    //     //         "Pool balance mismatch"
    //     //     );
    //     //     //Handle asset balances
    //     //     // emit log("Handle asset balances");
    //     //     for (uint256 i; i < amounts.length; i++) {
    //     //         if (payTokens[i] == address(pool)) continue;
    //     //         // emit log(pool.asset(payTokens[i]).symbol);
    //     //         uint256 index = pool.asset(payTokens[i]).index;
    //     //         c.balanceIncrease[index + 1] += amounts[i] * conversions[index];
    //     //     }
    //     //     for (uint256 i; i < receiveAmounts.length; i++) {
    //     //         if (receiveTokens[i] == address(pool)) continue;
    //     //         uint256 index = pool.asset(receiveTokens[i]).index;
    //     //         c.balanceDecrease[index + 1] +=
    //     //             receiveAmounts[i] *
    //     //             conversions[index];
    //     //     }
    //     //     // Check balances and scales
    //     //     for (uint256 i; i < assetStates.length + 1; i++) {
    //     //         // if (i == 0) emit log("Pool balance");
    //     //         // else emit log(assetStates[i + 1].symbol, "balance");
    //     //         assertEq(
    //     //             c.finalBalances[i],
    //     //             c.initialBalances[i] +
    //     //                 c.balanceIncrease[i] -
    //     //                 c.balanceDecrease[i],
    //     //             "Balance mismatch"
    //     //         );
    //     //         assertEq(
    //     //             c.finalScales[i],
    //     //             c.initialScales[i],
    //     //             "Scale mismatch"
    //     //         );
    //     //     }
    //     //     emit log("");
    //     //     emit log("");
    //     //     emit log("");
    //     //     emit log("");
    //     //     emit log("");
    //     //     emit log("");
    //     //     emit log(
    //     //         "==================================================================="
    //     //     );
    //     //     emit log(
    //     //         "Note: Check case where pool token amount in is less than fee amount"
    //     //     );
    //     //     emit log(
    //     //         "==================================================================="
    //     //     );
    //     //     // Compute scaled value flows
    //     //     c.scaledValueIn = 0;
    //     //     c.scaledValueOut = 0;
    //     //     // Handle pool scaled value flows
    //     //     if (payTokens[0] == address(pool)) {
    //     //         if (amounts[0] > feeAmount) {
    //     //             c.scaledValueIn += c.finalScales[0].fullMulDiv(
    //     //                 amounts[0].mulWadUp(c.initialTokensPerShare) -
    //     //                     feeAmount,
    //     //                 c.finalBalances[0]
    //     //             );
    //     //         } else {
    //     //             c.scaledValueOut += c.finalScales[0].fullMulDiv(
    //     //                 feeAmount -
    //     //                     amounts[0].mulWadUp(c.initialTokensPerShare),
    //     //                 c.finalBalances[0]
    //     //             );
    //     //         }
    //     //     } else if (receiveTokens[0] == address(pool)) {
    //     //         c.scaledValueOut += c.finalScales[0].fullMulDiv(
    //     //             receiveAmounts[0].mulWadUp(c.finalTokensPerShare) +
    //     //                 feeAmount,
    //     //             c.finalBalances[0]
    //     //         );
    //     //     } else {
    //     //         c.scaledValueOut += c.finalScales[0].fullMulDiv(
    //     //             feeAmount,
    //     //             c.finalBalances[0]
    //     //         );
    //     //     }
    //     //     // Handle asset scaled value flows
    //     //     for (uint256 i; i < amounts.length; i++) {
    //     //         if (payTokens[i] == address(pool)) continue;
    //     //         uint256 index = pool.asset(payTokens[i]).index;
    //     //         c.scaledValueIn += c.finalScales[index + 1].fullMulDiv(
    //     //             amounts[i] * conversions[index],
    //     //             c.finalBalances[index + 1]
    //     //         );
    //     //     }
    //     //     for (uint256 i; i < receiveAmounts.length; i++) {
    //     //         if (receiveTokens[i] == address(pool)) continue;
    //     //         uint256 index = pool.asset(receiveTokens[i]).index;
    //     //         c.scaledValueOut += c.finalScales[index + 1].fullMulDiv(
    //     //             receiveAmounts[i] * conversions[index],
    //     //             c.finalBalances[index + 1]
    //     //         );
    //     //     }
    //     //     // Determine significant digits
    //     //     uint256 significantDigits = type(uint256).max;
    //     //     for (uint256 i; i < amounts.length; i++) {
    //     //         uint256 digits = countDigits(amounts[i]);
    //     //         if (digits < significantDigits) {
    //     //             significantDigits = digits;
    //     //         }
    //     //     }
    //     //     // Determine the minimum token decimals from payTokens and receiveTokens
    //     //     uint256 minDecimals = type(uint256).max;
    //     //     for (uint256 i; i < payTokens.length; i++) {
    //     //         if (payTokens[i] == address(pool)) continue;
    //     //         uint256 decimals = pool.asset(payTokens[i]).decimals;
    //     //         if (decimals < minDecimals) {
    //     //             minDecimals = decimals;
    //     //         }
    //     //     }
    //     //     for (uint256 i; i < receiveTokens.length; i++) {
    //     //         if (receiveTokens[i] == address(pool)) continue;
    //     //         uint256 decimals = pool.asset(receiveTokens[i]).decimals;
    //     //         if (decimals < minDecimals) {
    //     //             minDecimals = decimals;
    //     //         }
    //     //     }
    //     //     // emit log_named_uint("Significant digits", significantDigits);
    //     //     // emit log_named_uint("Minimum decimals", minDecimals);
    //     //     // assertEq(
    //     //     //     scaledValueIn,
    //     //     //     scaledValueOut,
    //     //     //     "Scaled value in does not equal scaled value out"
    //     //     // );
    //     // assertApproxEqRel(
    //     //     c.scaledValueIn,
    //     //     c.scaledValueOut,
    //     //     10 ** (18 - minDecimals),
    //     //     "Scaled value in does not equal scaled value out"
    //     // );
    //     // }
    //     // fail();
    // }

    // function checkSwap(
    //     Pool pool,
    //     address payToken,
    //     address receiveToken,
    //     uint256 payAmount,
    //     uint256 checkReceiveAmount,
    //     uint256 checkFeeAmount,
    //     string memory message
    // ) public {
    //     address[] memory payTokens = new address[](1);
    //     payTokens[0] = payToken;
    //     uint256[] memory amounts = new uint256[](1);
    //     amounts[0] = payAmount;
    //     address[] memory receiveTokens = new address[](1);
    //     receiveTokens[0] = receiveToken;
    //     uint256[] memory allocations = new uint256[](1);
    //     allocations[0] = ONE;
    //     uint256[] memory checkReceiveAmounts = new uint256[](1);
    //     checkReceiveAmounts[0] = checkReceiveAmount;

    //     checkMultiswap(
    //         pool,
    //         payTokens,
    //         amounts,
    //         receiveTokens,
    //         allocations,
    //         checkReceiveAmounts,
    //         checkFeeAmount,
    //         message
    //     );
    // }

    // function checkStake(
    //     Pool pool,
    //     address payToken,
    //     uint256 amount
    // ) public {
    //     address[] memory payTokens = new address[](1);
    //     payTokens[0] = payToken;
    //     uint256[] memory amounts = new uint256[](1);
    //     amounts[0] = amount;
    //     address[] memory receiveTokens = new address[](1);
    //     receiveTokens[0] = address(pool);
    //     uint256[] memory allocations = new uint256[](1);
    //     allocations[0] = ONE;

    //     checkMultiswap(pool, payTokens, amounts, receiveTokens, allocations);
    // }

    // function checkUnstake(
    //     Pool pool,
    //     address receiveToken,
    //     uint256 amount // Shares 18 decimals
    // ) public {
    //     address[] memory payTokens = new address[](1);
    //     payTokens[0] = address(pool);
    //     uint256[] memory amounts = new uint256[](1);
    //     amounts[0] = amount;
    //     address[] memory receiveTokens = new address[](1);
    //     receiveTokens[0] = receiveToken;
    //     uint256[] memory allocations = new uint256[](1);
    //     allocations[0] = ONE;

    //     checkMultiswap(pool, payTokens, amounts, receiveTokens, allocations);
    // }

    // function checkMixedStake(
    //     Pool pool,
    //     address payToken,
    //     address receiveToken,
    //     uint256 amount
    // ) public {
    //     address[] memory payTokens = new address[](1);
    //     payTokens[0] = payToken;
    //     uint256[] memory amounts = new uint256[](1);
    //     amounts[0] = amount;
    //     address[] memory receiveTokens = new address[](2);
    //     receiveTokens[0] = address(pool);
    //     receiveTokens[1] = receiveToken;
    //     uint256[] memory allocations = new uint256[](2);
    //     allocations[0] = 5e17;
    //     allocations[1] = 5e17;

    //     checkMultiswap(pool, payTokens, amounts, receiveTokens, allocations);
    // }

    // function checkMixedUnstake(
    //     Pool pool,
    //     address payToken,
    //     address receiveToken,
    //     uint256 tokenAmount, // Token decimals
    //     uint256 shareAmount // Shares 18 decimals
    // ) public {
    //     address[] memory payTokens = new address[](2);
    //     payTokens[0] = address(pool);
    //     payTokens[1] = payToken;
    //     uint256[] memory amounts = new uint256[](2);
    //     amounts[0] = shareAmount;
    //     amounts[1] = tokenAmount;
    //     address[] memory receiveTokens = new address[](1);
    //     receiveTokens[0] = receiveToken;
    //     uint256[] memory allocations = new uint256[](1);
    //     allocations[0] = ONE;

    //     checkMultiswap(pool, payTokens, amounts, receiveTokens, allocations);
    // }

    // function checkAddLiquidity(
    //     Pool pool,
    //     address token,
    //     uint256 amount // 18 decimals
    // ) public {
    //     uint256 poolAmount_;
    //     uint256[] memory payAmounts_;
    //     (
    //         poolAmount_, // Internal decimals
    //         payAmounts_ // Internal decimals
    //     ) = pool._quoteAddLiquidity(token, amount);
    //     for (uint256 i; i < payAmounts_.length; i++) {
    //         emit log_named_uint("Pay amount", payAmounts_[i]);
    //     }
    //     emit log_named_uint("Pool amount", poolAmount_);
    // }

    // function checkRemoveLiquidity(
    //     Pool pool,
    //     uint256 amount // Shares 18 decimals
    // ) public {
    //     QuoteState memory q = pool._quoteRemoveLiquidity(amount);
    //     for (uint256 i; i < q.receiveTokens.length; i++) {
    //         emit log_named_uint(
    //             pool.asset(q.receiveTokens[i]).symbol,
    //             q.receiveAmounts[i]
    //         );
    //     }
    //     emit log_named_uint("Fee amount", q.feeAmount);
    // }
}
