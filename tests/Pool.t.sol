// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "../contracts/Pool.sol";
import "./Token.t.sol";
import "forge-std/src/Test.sol";

contract PoolTest is Test {
    using FixedPointMathLib for uint256;

    uint256 internal constant NTOKENS = 10;

    address internal alice = address(1);
    address internal bob = address(2);
    address internal carol = address(3);

    uint256[] internal fees = new uint256[](NTOKENS);
    uint256[] internal prices = new uint256[](NTOKENS);
    uint256[] internal conversions = new uint256[](NTOKENS);

    uint256 internal constant ONE = 1e18;
    uint256 internal constant PCT = 1e16;
    uint256 internal constant BPS = 1e14;

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

    uint256[] internal payAmounts;
    uint256[] internal receiveAmounts;
    uint256 internal feeAmount;

    function setUpPool(
        string memory name,
        string memory symbol,
        uint256 protocolFee,
        uint tau
    ) public returns (Pool pool, Token[] memory tokens) {
        pool = new Pool(name, symbol, protocolFee, tau, address(WAVAX));
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

        Token token;
        uint256 conversion;
        uint256 balance = marketCap.divWadUp(prices[0]);
        for (uint256 i; i < NTOKENS; i++) {
            token = tokens[i];
            conversion = 10 ** (18 - token.decimals());
            conversions[i] = conversion;
            balance = marketCap.divWadUp(prices[i]) / conversion;
            if (address(token) == address(WAVAX)) {
                vm.deal(address(token), balance);
            }
            token.mint(balance);
            token.approve(address(pool), balance);
            pool.addAsset(address(token), fees[i], balance, marketCap);
        }

        pool.initialize();

        for (uint256 i; i < NTOKENS; i++) {
            token = tokens[i];
            balance = token.balanceOf(address(pool));
            if (address(token) == address(WAVAX)) {
                vm.deal(address(token), balance);
            }
            token.mint(balance);
            token.approve(address(pool), balance);
        }
    }
}
