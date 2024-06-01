// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../test/Token.t.sol";
import "forge-std/Script.sol";
import "forge-std/Test.sol";

contract DeployTokensScript is Script, Test {
    uint256 public deployerPrivateKey = vm.envUint("PRIVATE_KEY");

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
        vm.startBroadcast(deployerPrivateKey);

        emit log_named_address("sender", msg.sender);
        uint256 n;
        tokens[n++] = new Token("Wrapped AVAX", "WAVAX", 18);
        tokens[n++] = new Token("USD Coin", "USDC", 6);
        tokens[n++] = new Token("TetherToken", "USDt", 6);
        tokens[n++] = new Token("Euro Coin", "EUROC", 6);
        tokens[n++] = new Token("Bridged USDC", "USDC.e", 6);
        tokens[n++] = new Token("Bridged USDt", "USDT.e", 6);
        tokens[n++] = new Token("Bridged DAI", "DAI.e", 18);
        tokens[n++] = new Token("Bridged WETH", "WETH.e", 18);
        tokens[n++] = new Token("Bridged WBTC", "WBTC.e", 8);
        tokens[n++] = new Token("Bridged BTC", "BTC.b", 8);

        for (uint256 i; i < n; i++) {
            token = tokens[i];
            emit log_named_address(token.symbol(), address(tokens[i]));
        }
    }
}
