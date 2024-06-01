// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../contracts/Pool.sol";
import "forge-std/Script.sol";
import "forge-std/Test.sol";

contract SetProtocolFeeScript is Script, Test {

    uint256 private deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address private poolAddress = vm.envAddress("POOL_ADDRESS");

    Pool private pool = Pool(payable(poolAddress));

    function run() external {
        vm.startBroadcast(deployerPrivateKey);

        pool.setProtocolFee(5e17);
    }
}
