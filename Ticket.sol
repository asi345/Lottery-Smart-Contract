// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract Ticket is ERC721 {

    uint256 public ticketNo;
    bytes32 public hash_rnd_number;
    /*
    0 for purchased
    1 for cancelled
    */ 
    uint8 public status;

    constructor(uint256 _ticketNo, address owner, bytes32 _hash_rnd_number) ERC721("Ticket", "TCK") {
        ticketNo = _ticketNo;
        hash_rnd_number = _hash_rnd_number;
        status = 0;
        _mint(owner, ticketNo);
        //_mint(owner, hash_rnd_number);
    }
}