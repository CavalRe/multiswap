// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "forge-std/src/Test.sol";
import "../contracts/Pool.sol";
import "./Token.t.sol";

contract InitTest is Test {
    function testInit() public {
        address alice = address(1);

        vm.startPrank(alice);

        Token tokenA = new Token("Foo", "FOOA", 18);
        Token tokenB = new Token("Foo", "FOOB", 18);
        Pool pool = new Pool("Pool", "P", 2e17, 1e16, address(tokenA));
        uint256 amount = 1e27;
        // uint256 minReceiveAmount = 0;

        // vm.expectRevert(abi.encodeWithSelector(IPool.NotInitialized.selector));
        // pool.stake(address(tokenA), amount, minReceiveAmount);
        // vm.expectRevert(abi.encodeWithSelector(IPool.NotInitialized.selector));
        // pool.unstake(address(tokenB), amount, minReceiveAmount);
        // vm.expectRevert(abi.encodeWithSelector(IPool.NotInitialized.selector));
        // pool.swap(address(tokenA), address(tokenB), amount, minReceiveAmount);

        tokenA.mint(amount);
        tokenA.approve(address(pool), amount);
        pool.addAsset(address(tokenA), 1e15, amount, 1e18);
        tokenB.mint(amount);
        tokenB.approve(address(pool), amount);
        pool.addAsset(address(tokenB), 1e15, amount, 1e18);

        vm.expectRevert(
            abi.encodeWithSelector(
                IPool.DuplicateToken.selector,
                address(tokenB)
            )
        );
        pool.addAsset(address(tokenB), 1e15, amount, 1e18);

        uint256 balanceBefore = tokenA.balanceOf(alice);
        pool.removeAsset(address(tokenA));

        pool.assets();

        assertEq(tokenA.balanceOf(alice) - balanceBefore, amount);

        vm.expectRevert(
            abi.encodeWithSelector(
                IPool.AssetNotFound.selector,
                address(tokenA)
            )
        );
        pool.removeAsset(address(tokenA));

        balanceBefore = tokenB.balanceOf(alice);
        pool.removeAsset(address(tokenB));

        pool.assets();

        assertEq(tokenB.balanceOf(alice) - balanceBefore, amount);

        tokenA.mint(amount);
        tokenA.approve(address(pool), amount);
        pool.addAsset(address(tokenA), 1e15, amount, 1e18);
        tokenB.mint(amount);
        tokenB.approve(address(pool), amount);
        pool.addAsset(address(tokenB), 1e15, amount, 1e18);

        pool.initialize();

        vm.expectRevert(
            abi.encodeWithSelector(IPool.AlreadyInitialized.selector)
        );
        pool.addAsset(address(tokenB), 1e15, amount, 1e18);
        vm.expectRevert(
            abi.encodeWithSelector(IPool.AlreadyInitialized.selector)
        );
        pool.initialize();

        AssetState[] memory assets = pool.assets();
        for (uint256 i; i < assets.length; i++) {
            address token = assets[i].token;
            assertEq(token, assets[assets[i].index].token);
        }

        vm.stopPrank();
    }

    function testFailInit() public {
        address alice = address(1);
        address bob = address(2);

        vm.startPrank(alice);
        Pool pool = new Pool("Pool", "P", 2e17, 1e16, address(1234));
        vm.stopPrank();

        vm.startPrank(bob);
        pool.initialize();
        vm.stopPrank();
    }

    function testFailAdd() public {
        address alice = address(1);
        address bob = address(2);

        Token tokenA = new Token("Foo", "FOOA", 18);

        vm.startPrank(alice);
        Pool pool = new Pool("Pool", "P", 2e17, 1e16, address(tokenA));
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 amount = 1e18;
        tokenA.mint(amount);
        tokenA.approve(address(pool), amount);
        pool.addAsset(address(tokenA), 1e15, amount, 1e18);
        vm.stopPrank();
    }
}
