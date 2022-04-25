// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Lottery {

/*
users will provide the random numbers
for winning number, we will xor or get mean of them, just manipulate the given ones
2 stages: first stage, users will take the hash of the random numbers and send them since
the numbers are visible in EVM, they will commit the random number
in second stage, they will reveal the commit, revealing will be public
after revealing, we will use the random numbers to produce the winner number, which will be the
index for the array, then person can withdraw the prize money

just deploy and use ERC20 token contract in the code, give the name of TL into it and use
inherit ERC721 token contract in the code and modify it in the Lottery contract, do not modify
the given token contracts

tokens should only be transferred(unless needed) in deposit and withdraw functions

for each address, a ticket list, linked list or array
*/
    address public admin;
    address payable[] public users;

    constructor() public {
        admin = msg.sender;
    }

    fallback() external {
        revert();
    }

    function depositTL(uint amnt) public {

    }

    function withdrawTL(uint amnt) public {

    }

    function buyTicket(bytes32 hash_rnd_number) public {

    }
    // does not implement an actual transfer, just update the user's account balance
    function collectTicketRefund(uint ticket_no) public {

    }

    function revealRndNumber(uint ticketno, uint rnd_number) public {

    }
    // last bought ticket for a specific person, status - for example someone has bought a ticket
    // but did not reveal it and it has been cancelled, or if the ticket has been transferred to
    // someone else, it can be 'no longer owned', don't delete the tickets until the lottery ends
    function getLastOwnedTicketNo(uint lottery_no) public view returns(uint, uint8 status) {

    }
    // again, for a specific person
    function getIthOwnedTicketNo(uint i, uint lottery_no) public view returns(uint, uint8 status) {

    }

    function checkIfTicketWon(uint ticket_no) public view returns (uint amount) {

    }

    function collectTicketPrize(uint ticket_no) public {

    }

    function getIthWinningTicket(uint i, uint lottery_no) public view returns (uint ticket_no, uint amount) {
        
    }
    
    function getLotteryNo(uint unixtimeinweek) public view returns (uint lottery_no) {

    }

    function getTotalLotteryMoneyCollected(uint lottery_no) public view returns (uint amount) {

    }
    
}