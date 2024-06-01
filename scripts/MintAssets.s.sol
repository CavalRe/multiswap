// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../contracts/Pool.sol";
import "../test/Token.t.sol";
import "forge-std/Script.sol";
import "forge-std/Test.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";

contract MintAssetsScript is Script, Test {
    using FixedPointMathLib for uint256;

    uint256 private deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address private deployer = vm.addr(deployerPrivateKey);
    Pool private pool;
    address[] private tokens = new address[](10);

    function setUp() public {
        pool = Pool(payable(vm.envAddress("POOL_ADDRESS")));
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
        vm.startBroadcast(deployerPrivateKey);

        for (uint256 i = 0; i < tokens.length; i++) {
            Token token = Token(payable(tokens[i]));
            uint256 balance = token.balanceOf(address(pool));
            if (balance > 0) {
                token.mint(balance / 10);
            }
        }
    }
}
