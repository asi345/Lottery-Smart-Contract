// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract Ticket is ERC721 {

    uint256 public ticketNo;

    constructor(uint256 _ticketNo) ERC721("Ticket", "TCK") {
        ticketNo = _ticketNo;
    }
}