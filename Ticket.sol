// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract Ticket is ERC721 {

    uint256 private ticketNo;
    bytes32 private hash_rnd_number;
    /* status:
    0 for purchased
    1 for cancelled
    2 for no longer owned
    3 for revealed correctly
    */ 
    uint8 public status;
    // built inlerde karisiklik cikabilir gibi, sikerler kendimiz yazalim
    address private owner;

    constructor(uint256 _ticketNo, address _owner, bytes32 _hash_rnd_number) ERC721("Ticket", "TCK") {
        ticketNo = _ticketNo;
        hash_rnd_number = _hash_rnd_number;
        status = 0;
        owner = _owner;
    }

    function getTicketNo() public view returns (uint256) {
        return ticketNo;
    }

    function getHash_rnd_number() public view returns (bytes32) {
        return hash_rnd_number;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function setStatus(uint8 _status) public {
        status = _status;
    }
}