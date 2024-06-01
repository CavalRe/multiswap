// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../contracts/Pool.sol";
import "../test/Token.t.sol";
import "forge-std/Script.sol";
import "forge-std/Test.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";

contract DeployPoolScript is Script, Test {
    using FixedPointMathLib for uint256;

    uint256 public deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    Pool private pool;
    uint256 private protocolFee = 5e17;
    uint256 private tau = 1e16;
    uint256 private bps = 1e14;
    uint256 private marketCap = 1e26;

    address[] private tokens = new address[](10);

    Token token;
    uint256[] private fees = new uint256[](10);
    uint256[] private prices = new uint256[](10);
    uint256[] private weights = new uint256[](10);

    function setUp() public {
        fees[0] = 20 * bps;
        fees[1] = 1 * bps;
        fees[2] = 1 * bps;
        fees[3] = 1 * bps;
        fees[4] = 1 * bps;
        fees[5] = 1 * bps;
        fees[6] = 1 * bps;
        fees[7] = 20 * bps;
        fees[8] = 20 * bps;
        fees[9] = 20 * bps;

        prices[0] = 127e17;
        prices[1] = 1e18;
        prices[2] = 1e18;
        prices[3] = 110e16;
        prices[4] = 1e18;
        prices[5] = 1e18;
        prices[6] = 1e18;
        prices[7] = 1848e18;
        prices[8] = 29173e18;
        prices[9] = 29173e18;

        weights[0] = 250e15;
        weights[1] = 250e15;
        weights[2] = 100e15;
        weights[3] = 50e15;
        weights[4] = 25e15;
        weights[5] = 50e15;
        weights[6] = 25e15;
        weights[7] = 100e15;
        weights[8] = 25e15;
        weights[9] = 125e15;

        tokens[0] = vm.envAddress("WAVAX_ADDRESS");
        tokens[1] = vm.envAddress("USDC_ADDRESS");
        tokens[2] = vm.envAddress("USDt_ADDRESS");
        tokens[3] = vm.envAddress("EUROC_ADDRESS");
        tokens[4] = vm.envAddress("USDCe_ADDRESS");
        tokens[5] = vm.envAddress("USDTe_ADDRESS");
        tokens[6] = vm.envAddress("DAIe_ADDRESS");
        tokens[7] = vm.envAddress("WETHe_ADDRESS");
        tokens[8] = vm.envAddress("WBTCe_ADDRESS");
        tokens[9] = vm.envAddress("BTCb_ADDRESS");
    }

    function run() external {
        emit log_named_uint("deployer", deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        pool = new Pool(
            "Pool",
            "P",
            protocolFee,
            tau,
            vm.envAddress("WRAPPED_NATIVE_TOKEN")
        );

        emit log_named_address("pool address", address(pool));
        emit log_named_address("pool owner", address(pool.owner()));
        emit log_named_address("sender", msg.sender);

        uint256 value;
        uint256 balance;
        uint256 conversion;
        for (uint256 i; i < 10; i++) {
            token = Token(payable(tokens[i]));
            conversion = 10 ** (18 - token.decimals());
            value = marketCap.mulWadUp(weights[i]);
            balance = value.divWadUp(prices[i]) / conversion;
            token.mint(balance);
            token.approve(address(pool), balance);
            pool.addAsset(address(token), fees[i], balance, value);
        }

        pool.initialize();
    }
}
