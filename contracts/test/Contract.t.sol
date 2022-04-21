// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../Token.sol";
import "../Pool.sol";
import "../libraries/ds-test/src/test.sol";

contract ContractTest is Context, DSTest {

    uint256 private constant NTOKENS = 10;
    Token[] private tokens;

    Pool private pool;

    address private sender;

    address[] private addresses;
    uint256[] private amounts;

    address private pay1Asset;
    address private receive1Asset;
    address private poolAddress;

    uint256 private pay1Amount;

    address[] private pay1Assets = new address[](1);
    uint256[] private pay1Amounts = new uint256[](1);
    address[] private receive1Assets = new address[](1);
    address[] private receive1Pools = new address[](1);
    uint256[] private allocations1 = new uint256[](1);

    address[] private pay2Assets = new address[](2);
    uint256[] private pay2Amounts = new uint256[](2);
    address[] private receive2Assets = new address[](2);
    address[] private receive1Asset1Pool = new address[](2);
    uint256[] private allocations2 = new uint256[](2);

    function setUp() public {
        tokens = new Token[](NTOKENS);

        pool = new Pool("Pool", "P");

        addresses = new address[](NTOKENS);
        amounts = new uint256[](NTOKENS);
        uint256[] memory reserves = new uint256[](NTOKENS);
        uint256[] memory fees = new uint256[](NTOKENS);
        uint256[] memory weights = new uint256[](NTOKENS);
        uint256[] memory ks = new uint256[](NTOKENS);

        for (uint256 i = 0; i < NTOKENS; i++) {
            // Generate token
            string memory name = string(
                abi.encodePacked("Token ", Strings.toString(i + 1))
            );
            string memory symbol = string(
                abi.encodePacked("T", Strings.toString(i + 1))
            );
            uint256 supply = (i+1)*1e22;
            uint256 balance = supply / 10;
            Token token = new Token(name, symbol, supply);
            token.approve(address(pool), balance);
            tokens[i] = token;

            //Generate asset info
            addresses[i] = address(token);
            reserves[i] = balance;
            fees[i] = 3e15;
            weights[i] = 1e18 / NTOKENS;
            ks[i] = 1e18;
        }

        pool.initialize(1e23, addresses, reserves, fees, weights, ks);

        sender = address(this);

        for (uint256 i = 0; i < NTOKENS; i++) {
            amounts[i] = pool.balance(addresses[i]) / 10;
            tokens[i].increaseAllowance(address(pool), amounts[i]);
        }

        pay1Asset = addresses[0];
        receive1Asset = addresses[1];
        poolAddress = address(pool);
        pay1Amount = amounts[0];
        
        pay1Assets[0] = addresses[0];
        pay1Amounts[0] = amounts[0];

        receive1Assets[0] = addresses[1];
        receive1Pools[0] = address(pool);
        allocations1[0] = 1e18;

        pay2Assets[0] = addresses[0];
        pay2Assets[1] = addresses[2];
        pay2Amounts[0] = amounts[0];
        pay2Amounts[1] = amounts[2];

        receive2Assets[0] = addresses[1];
        receive2Assets[1] = addresses[3];

        receive1Asset1Pool[0] = addresses[0];
        receive1Asset1Pool[1] = address(pool);
    }

    // function testPool() public {
    //     assertEq(pool.totalSupply(), 1e23);
    //     for (uint256 i = 0; i < NTOKENS; i++) {
    //         Token token = tokens[i];
    //         uint256 supply = (i+1)*1e18;
    //         uint256 balance = supply / 10;
    //         assertEq(token.totalSupply(), supply);
    //         assertEq(pool.balance(address(token)), balance);
    //         assertEq(token.balanceOf(address(this)), supply - balance);
    //     }
    // }

    function testSwap() public {
        pool.swap(pay1Asset, receive1Asset, pay1Amount, sender);
    }

    function testSwapVerbose() public {
        // console.log("2-asset swap");
        // console.log("Pool:", pool.balance());
        // console.log("Token in:", pool.balance(addresses[0]));
        // console.log("Token out:", pool.balance(addresses[1]));
        // console.log("Fee out:", pool.fee(addresses[1]));
        // console.log("Amount in", pay1Amount);
        uint256 amountOut = pool.swap(pay1Asset, receive1Asset, pay1Amount, sender);
        console.log("Amount out", amountOut);
    }

    function testMultiswapP1AssetR1Asset() public {
        pool.multiswap(pay1Assets, pay1Amounts, receive1Assets, allocations1);
    }

    function testMultiswapP1AssetR1AssetVerbose() public {
        // console.log("Multiswap (2 assets)");
        // console.log("Pool:", pool.balance());
        // console.log("Token in:", pool.balance(pay1Assets[0]));
        // console.log("Token out:", pool.balance(receive1Assets[0]));
        // console.log("Fee out:", pool.fee(receive1Assets[0]));
        // console.log("Amount in", pay1Amounts[0]);
        uint256[] memory amountsOut = pool.multiswap(pay1Assets, pay1Amounts, receive1Assets, allocations1);
        console.log("Amount out", amountsOut[0]);
    }

    function testMultiswapP1AssetR1Pool() public {
        pool.multiswap(pay1Assets, pay1Amounts, receive1Pools, allocations1);
    }

    function testMultiswapP1AssetR1PoolVerbose() public {
        // console.log("Multiswap (stake)");
        // console.log("Pool:", pool.balance());
        // console.log("Token in:", pool.balance(pay1Assets[0]));
        // console.log("Fee out:", pool.fee());
        // console.log("Amount in", pay1Amounts[0]);
        uint256[] memory amountsOut = pool.multiswap(pay1Assets, pay1Amounts, receive1Pools, allocations1);
        console.log("Amount out", amountsOut[0]);
    }

    // function testSwapVerbose() public {
    //     emit log("============");
    //     emit log("Before swap:");
    //     emit log("============");
    //     emit log_named_uint("Weight 1", pool.weight(addresses[0]));
    //     emit log_named_uint("Weight 2", pool.weight(addresses[1]));
    //     emit log_named_uint("Reserve 0", pool.totalSupply());
    //     emit log_named_uint("Balance 1", tokens[0].balanceOf(address(pool)));
    //     emit log_named_uint("Reserve 1", pool.balance(addresses[0]));
    //     emit log_named_uint("Balance 2", tokens[1].balanceOf(address(pool)));
    //     emit log_named_uint("Reserve 2", pool.balance(addresses[1]));
    //     emit log_named_uint("Swap In Amount", amountIn);

    //     amountOut = pool.swap(addresses[0], addresses[1], amountIn, sender);

    //     emit log("===========");
    //     emit log("After swap:");
    //     emit log("===========");
    //     emit log_named_uint("Swap Out Amount", amountOut);
    //     emit log_named_uint("Weight 1", pool.weight(addresses[0]));
    //     emit log_named_uint("Weight 2", pool.weight(addresses[1]));
    //     emit log_named_uint("Reserve 0", pool.totalSupply());
    //     emit log_named_uint("Balance 1", tokens[0].balanceOf(address(pool)));
    //     emit log_named_uint("Reserve 1", pool.balance(addresses[0]));
    //     emit log_named_uint("Balance 2", tokens[1].balanceOf(address(pool)));
    //     emit log_named_uint("Reserve 2", pool.balance(addresses[1]));
    // }

    function testStake() public {
        // amountOut = 
        pool.stake(pay1Asset, amounts[0], sender);
        // console.log("Amount out:", amountOut);
    }

    // function testStakeVerbose() public {
    //     emit log("=============");
    //     emit log("Before stake:");
    //     emit log("=============");
    //     emit log_named_uint("Weight 1", pool.weight(addresses[0]));
    //     emit log_named_uint("Weight 2", pool.weight(addresses[1]));
    //     emit log_named_uint("Reserve 0", pool.totalSupply());
    //     emit log_named_uint("Balance 1", tokens[0].balanceOf(address(pool)));
    //     emit log_named_uint("Reserve 1", pool.balance(addresses[0]));
    //     emit log_named_uint("Balance 2", tokens[1].balanceOf(address(pool)));
    //     emit log_named_uint("Reserve 2", pool.balance(addresses[1]));
    //     emit log_named_uint("Swap In Amount", amountIn);

    //     amountOut = pool.stake(addresses[0], amountIn, sender);

    //     emit log("============");
    //     emit log("After stake:");
    //     emit log("============");
    //     emit log_named_uint("Swap Out Amount", amountOut);
    //     emit log_named_uint("Weight 1", pool.weight(addresses[0]));
    //     emit log_named_uint("Weight 2", pool.weight(addresses[1]));
    //     emit log_named_uint("Reserve 0", pool.totalSupply());
    //     emit log_named_uint("Balance 1", tokens[0].balanceOf(address(pool)));
    //     emit log_named_uint("Reserve 1", pool.balance(addresses[0]));
    //     emit log_named_uint("Balance 2", tokens[1].balanceOf(address(pool)));
    //     emit log_named_uint("Reserve 2", pool.balance(addresses[1]));
    // }

    // function testStakeBatch() public {
    //     for (uint256 i = 0; i < NTOKENS; i++) {
    //         tokens[i].increaseAllowance(address(pool), amountIn);
    //     }

    //     amountOut = pool.stakeBatch(addresses, amounts, sender);
    // }

    // function testCompareStakes() public {
    //     tokens[0].increaseAllowance(address(pool), 2 * amountIn);

    //     uint256 amountSingle = pool.stake(addresses[0], amountIn, sender);

    //     setUp();

    //     address[] memory addressInArray = new address[](1);
    //     uint256[] memory amountInArray = new uint256[](1);
    //     addressInArray[0] = addresses[0];
    //     amountInArray[0] = amountIn;

    //     uint256 amountBatch = pool.stakeBatch(
    //         addressInArray,
    //         amountInArray,
    //         sender
    //     );

    //     assertEq(
    //         amountSingle,
    //         amountBatch,
    //         "Single stake and batch stake do not agrees."
    //     );
    // }

    // function testUnstake() public {
    //     pool.increaseAllowance(address(pool), amountIn);

    //     amountOut = pool.unstake(addresses[0], amountIn, sender);
    // }

    // function testFailUnstakeNoAllowance() public {
    //     amountOut = pool.unstake(addresses[0], amountIn, sender);
    // }

    // function testUnstakeVerbose() public {
    //     pool.increaseAllowance(address(pool), amountIn);

    //     emit log("===============");
    //     emit log("Before unstake:");
    //     emit log("===============");
    //     emit log_named_uint("Weight 1", pool.weight(addresses[0]));
    //     emit log_named_uint("Weight 2", pool.weight(addresses[1]));
    //     emit log_named_uint("Reserve 0", pool.totalSupply());
    //     emit log_named_uint("Balance 1", tokens[0].balanceOf(address(pool)));
    //     emit log_named_uint("Reserve 1", pool.balance(addresses[0]));
    //     emit log_named_uint("Balance 2", tokens[1].balanceOf(address(pool)));
    //     emit log_named_uint("Reserve 2", pool.balance(addresses[1]));
    //     emit log_named_uint("Swap In Amount", amountIn);

    //     amountOut = pool.unstake(addresses[0], amountIn, sender);

    //     emit log("==============");
    //     emit log("After unstake:");
    //     emit log("==============");
    //     emit log_named_uint("Swap Out Amount", amountOut);
    //     emit log_named_uint("Weight 1", pool.weight(addresses[0]));
    //     emit log_named_uint("Weight 2", pool.weight(addresses[1]));
    //     emit log_named_uint("Reserve 0", pool.totalSupply());
    //     emit log_named_uint("Balance 1", tokens[0].balanceOf(address(pool)));
    //     emit log_named_uint("Reserve 1", pool.balance(addresses[0]));
    //     emit log_named_uint("Balance 2", tokens[1].balanceOf(address(pool)));
    //     emit log_named_uint("Reserve 2", pool.balance(addresses[1]));
    // }

    // function testAddAsset() public {
    //     tokens[0].increaseAllowance(address(pool), amountIn);
    //     tokenNew.increaseAllowance(address(pool), amountNew);

    //     pool.addAsset(
    //         addresses[0],
    //         addressNew,
    //         amountIn,
    //         amountNew,
    //         3e15,
    //         1e18,
    //         sender
    //     );
    // }
}
