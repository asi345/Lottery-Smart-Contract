// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract TL is ERC20 {
    constructor(uint amount) public ERC20("TurkishLira", "TL") {
        _mint(msg.sender, amount);
    }

    function mint(address to, uint amount) public {
        _mint(to, amount);
    }
}