// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "forge-std/Test.sol";

import "@cavalre/test/Token.t.sol";
import "@cavalre/Pool.sol";

contract ContractTest is Context, Test {
    uint256 private constant NTOKENS = 2;

    Token[] private tokens;

    Pool private pool;

    address private sender = address(this);

    address[] private addresses;
    uint256[] private fees;
    uint256[] private scales;
    uint256[] private amounts;

    address[] private oneAsset = new address[](1);
    address[] private anotherAsset = new address[](1);
    address[] private onePool = new address[](1);
    uint256[] private oneAmount = new uint256[](1);
    uint256[] private oneAllocation = new uint256[](1);

    address[] private twoTokens = new address[](2);
    uint256[] private twoAmounts = new uint256[](2);
    uint256[] private twoAllocations = new uint256[](2);

    uint256 private amountOut;
    uint256[] private receiveAmounts;
    uint256 private feeAmount;

    function setUp() public {
        address alice = address(1);

        vm.startPrank(alice);

        pool = new Pool("Pool", "P", int256(1e16), false);
        tokens = new Token[](NTOKENS);

        pool.addUser(alice, 0);

        addresses = new address[](NTOKENS);
        amounts = new uint256[](NTOKENS);
        fees = new uint256[](NTOKENS);
        scales = new uint256[](NTOKENS);

        uint256 amount;
        uint256 balance;
        uint256 scale = 1e27;
        uint256 fee = 1e15;

        string memory name;
        string memory symbol;

        for (uint256 i = 0; i < NTOKENS; i++) {
            amount = (i + 1) * 1e27;
            balance = 100 * amount;
            scale = balance;
            name = string(abi.encodePacked("Token ", Strings.toString(i + 1)));
            symbol = string(abi.encodePacked("T", Strings.toString(i + 1)));
            Token token = new Token(name, symbol);
            token.mint(balance);
            token.approve(address(pool), balance);
            tokens[i] = token;

            pool.addAsset(address(token), balance, fee, scale);

            addresses[i] = address(token);
            amounts[i] = amount;
            fees[i] = fee;
            scales[i] = scale;
        }

        pool.initialize();

        tokens[0].mint(amounts[0]);
        tokens[0].approve(address(pool), amounts[0]);

        oneAsset[0] = addresses[0];
        anotherAsset[0] = addresses[1];
        onePool[0] = address(pool);
        oneAmount[0] = amounts[0];
        oneAllocation[0] = 1e18;
    }

    function showAsset(AssetState memory _asset) internal {
        emit log_named_string("name", _asset.name);
        // emit log_named_string("symbol", _asset.symbol);
        // emit log_named_uint("balanceOf", _asset.token.balanceOf(address(pool)));
        emit log_named_uint("balance", _asset.balance);
        emit log_named_uint("scale", _asset.scale);
        emit log_named_uint("fee", _asset.fee);
        console.log("-------");
    }

    function showPool(Pool _pool) internal {
        PoolState memory pool_;
        console.log("Pool Info");
        console.log("=========");
        pool_ = _pool.info();
        // console.log("Name:",poolName);
        // console.log("Symbol:",poolSymbol);
        // emit log_named_uint("Decimals", poolDecimals);
        // emit log_named_uint("totalSupply", pool.totalSupply());
        emit log_named_uint("balance", pool_.balance);
        emit log_named_uint("scale", pool_.scale);
        console.log("");
        console.log("Assets:");
        console.log("-------");
        for (uint256 i; i < NTOKENS; i++) {
            showAsset(pool.asset(addresses[i]));
        }
    }

    function test1_1_Multiswap() public {
        pool.multiswap(oneAsset, oneAmount, anotherAsset, oneAllocation);
    }

    function test1_2_Swap() public {
        pool.swap(oneAsset[0], anotherAsset[0], oneAmount[0]);
    }

    function test1_3_Multistake() public {
        pool.multiswap(oneAsset, oneAmount, onePool, oneAllocation);
    }

    function test1_4_Stake() public {
        pool.stake(oneAsset[0], oneAmount[0]);
    }

    function test1_5_Multiunstake() public {
        pool.multiswap(oneAsset, oneAmount, onePool, oneAllocation);
    }

    function test1_6_Unstake() public {
        pool.unstake(oneAsset[0], oneAmount[0]);
    }

    function test2_1_Swapping() public {
        emit log("Initial state");
        emit log("");
        showPool(pool);
        emit log("");
        (receiveAmounts, feeAmount) = pool.multiswap(
            oneAsset,
            oneAmount,
            anotherAsset,
            oneAllocation
        );
        emit log("State after multiswap");
        emit log("");
        emit log_named_uint("amountIn", oneAmount[0]);
        emit log_named_uint("amountOut", receiveAmounts[0]);
        emit log_named_uint("feeAmount", feeAmount);
        emit log("");
        showPool(pool);
        emit log("");

        setUp();
        (amountOut, feeAmount) = pool.swap(
            oneAsset[0],
            anotherAsset[0],
            oneAmount[0]
        );
        emit log("State after swap");
        emit log("");
        emit log_named_uint("amountIn", oneAmount[0]);
        emit log_named_uint("amountOut", amountOut);
        emit log_named_uint("feeAmount", feeAmount);
        emit log("");
        showPool(pool);
        emit log("");

        vm.expectRevert(
            abi.encodeWithSelector(
                Pool.InvalidSwap.selector,
                address(pool),
                anotherAsset[0]
            )
        );
        pool.swap(address(pool), anotherAsset[0], oneAmount[0]);

        vm.expectRevert(
            abi.encodeWithSelector(
                Pool.InvalidSwap.selector,
                oneAsset[0],
                address(pool)
            )
        );
        pool.swap(oneAsset[0], address(pool), oneAmount[0]);
    }

    function test2_2_Staking() public {
        (receiveAmounts, feeAmount) = pool.multiswap(
            oneAsset,
            oneAmount,
            onePool,
            oneAllocation
        );
        amountOut = receiveAmounts[0];
        emit log("Multiswap:");
        emit log("");
        emit log_named_uint("amountIn", oneAmount[0]);
        emit log_named_uint("amountOut", amountOut);
        emit log("");

        setUp();
        amountOut = pool.stake(oneAsset[0], amounts[0]);

        emit log("Stake:");
        emit log("");
        emit log_named_uint("amountIn", amounts[0]);
        emit log_named_uint("amountOut", amountOut);

        vm.expectRevert(
            abi.encodeWithSelector(Pool.InvalidStake.selector, address(pool))
        );
        pool.stake(address(pool), amounts[0]);
    }

    function test2_3_Unstaking() public {
        emit log("Initial state");
        emit log("");
        showPool(pool);
        emit log("");
        (receiveAmounts, feeAmount) = pool.multiswap(
            onePool,
            oneAmount,
            anotherAsset,
            oneAllocation
        );
        amountOut = receiveAmounts[0];
        emit log("State after multiswap");
        emit log("");
        emit log_named_string("Pay token:", pool.info().name);
        emit log_named_string(
            "Receive token:",
            pool.asset(anotherAsset[0]).name
        );
        emit log_named_uint("amountIn", oneAmount[0]);
        emit log_named_uint("amountOut", amountOut);
        emit log_named_uint("feeAmount", feeAmount);
        emit log("");
        showPool(pool);
        emit log("");

        setUp();
        (amountOut, feeAmount) = pool.unstake(anotherAsset[0], oneAmount[0]);
        emit log("State after unstake");
        emit log("");
        emit log_named_uint("amountIn", oneAmount[0]);
        emit log_named_uint("amountOut", amountOut);
        emit log_named_uint("feeAmount", feeAmount);
        emit log("");
        showPool(pool);
        emit log("");

        vm.expectRevert(
            abi.encodeWithSelector(Pool.InvalidUnstake.selector, address(pool))
        );
        pool.unstake(address(pool), amounts[0]);
    }

    function test2_4_MixedStaking() public {
        twoTokens[0] = address(pool);
        twoTokens[1] = anotherAsset[0];
        twoAmounts[0] = 5e17;
        twoAmounts[1] = 5e17;
        emit log("Initial state");
        emit log("");
        showPool(pool);
        emit log("");
        (receiveAmounts, feeAmount) = pool.multiswap(
            oneAsset,
            oneAmount,
            twoTokens,
            twoAmounts
        );
        emit log("State after mixed stake");
        emit log("");
        emit log_named_string("Pay token:", pool.info().name);
        emit log_named_string("Receive token 1:", pool.info().name);
        emit log_named_string(
            "Receive token 2:",
            pool.asset(anotherAsset[0]).name
        );
        emit log_named_uint("amountIn", oneAmount[0]);
        emit log_named_uint("amountOut 1", receiveAmounts[0]);
        emit log_named_uint("amountOut 2", receiveAmounts[1]);
        emit log_named_uint("feeAmount", feeAmount);
        emit log_named_uint("poolOut", receiveAmounts[0] + feeAmount);
        emit log("");
        showPool(pool);
        emit log("");
    }

    function test2_5_MixedUnstaking() public {
        twoTokens[0] = address(pool);
        twoTokens[1] = oneAsset[0];
        twoAmounts[0] = oneAmount[0];
        twoAmounts[1] = oneAmount[0];
        emit log("Initial state");
        emit log("");
        showPool(pool);
        emit log("");
        (receiveAmounts, feeAmount) = pool.multiswap(
            twoTokens,
            twoAmounts,
            anotherAsset,
            oneAllocation
        );
        emit log("State after mixed unstake");
        emit log("");
        emit log_named_string("Pay token 1:", pool.info().name);
        emit log_named_string("Pay token 2:", pool.asset(oneAsset[0]).name);
        emit log_named_string(
            "Receive token:",
            pool.asset(anotherAsset[0]).name
        );
        emit log_named_uint("amountIn 1", twoAmounts[0]);
        emit log_named_uint("amountIn 2", twoAmounts[1]);
        emit log_named_uint("amountOut", receiveAmounts[0]);
        emit log_named_uint("feeAmount", feeAmount);
        emit log("");
        showPool(pool);
        emit log("");
    }
}
