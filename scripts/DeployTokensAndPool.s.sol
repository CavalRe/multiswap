// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../contracts/Pool.sol";
import "../test/Token.t.sol";
import "forge-std/Script.sol";
import "forge-std/Test.sol";

contract DeployTokensAndPoolScript is Script, Test {
    using FixedPointMathLib for uint256;

    uint256 public deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    Pool private pool;
    uint256 private protocolFee = 5e17;
    uint256 private tau = 1e16;
    uint256 private bps = 1e14;
    uint256 private marketCap = 1e25;

    Token[] private tokens = new Token[](10);

    Token token;
    uint256[] private fees = new uint256[](10);
    uint256[] private prices = new uint256[](10);

    function setUp() public {
        fees[0] = 15 * bps;
        fees[1] = 5 * bps;
        fees[2] = 5 * bps;
        fees[3] = 5 * bps;
        fees[4] = 5 * bps;
        fees[5] = 5 * bps;
        fees[6] = 5 * bps;
        fees[7] = 30 * bps;
        fees[8] = 30 * bps;
        fees[9] = 30 * bps;

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
    }

    function run() external {
        emit log_named_uint("deployer", deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);



        tokens[0] = new Token("Wrapped AVAX", "WAVAX", 18);
        tokens[1] = new Token("USD Coin", "USDC", 6);
        tokens[2] = new Token("TetherToken", "USDt", 6);
        tokens[3] = new Token("Euro Coin", "EUROC", 6);
        tokens[4] = new Token("Bridged USDC", "USDC.e", 6);
        tokens[5] = new Token("Bridged USDt", "USDT.e", 6);
        tokens[6] = new Token("Bridged DAI", "DAI.e", 18);
        tokens[7] = new Token("Bridged WETH", "WETH.e", 18);
        tokens[8] = new Token("Bridged WBTC", "WBTC.e", 8);
        tokens[9] = new Token("Bridged BTC", "BTC.b", 8);

        pool = new Pool(
            "Pool",
            "P",
            protocolFee,
            tau,
            vm.envAddress("WRAPPED_NATIVE_TOKEN")
        );

        emit log_named_address("pool owner", address(pool.owner()));
        emit log_named_address("sender", msg.sender);
        uint256 balance;
        uint256 conversion;
        for (uint256 i; i < 10; i++) {
            token = tokens[i];
            emit log_named_address(token.symbol(), address(tokens[i]));

            conversion = 10 ** (18 - token.decimals());
            balance = marketCap.divWadUp(prices[i]) / conversion;
            token.mint(balance);
            token.approve(address(pool), balance);
            pool.addAsset(address(token), fees[i], balance, marketCap);
        }

        pool.initialize();
    }
}
