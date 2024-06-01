// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/src/Test.sol";

contract Token is ERC20, Test {
    uint8 private _decimals;

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
    }

    function mint(uint256 amount) public virtual {
        _mint(_msgSender(), amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        _mint(_msgSender(), msg.value);
        emit Deposit(_msgSender(), msg.value);
    }

    function withdraw(uint256 wad) public {
        require(balanceOf(_msgSender()) >= wad);
        _burn(_msgSender(), wad);
        (bool success, ) = payable(_msgSender()).call{value: wad}("");
        require(success, "Transfer failed");
        emit Withdrawal(_msgSender(), wad);
    }
}
