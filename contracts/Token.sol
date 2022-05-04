// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint totalSupply
    ) ERC20(name, symbol) {
        _mint(_msgSender(), totalSupply);
    }

    function mint(uint256 amount) public virtual {
        _mint(_msgSender(), amount);
    }
}
