// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./Ticket.sol";

contract Lottery {


    //mybalance function should also be implemented  hoca öyle demiş

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
    mapping(address => uint256) public balances;
    ERC20 public token;
    mapping(uint256 => Ticket) public ticketsFromNo;
    mapping(uint256 => mapping(address => Ticket[])) public ticketsFromLottery;
    uint256 public ticketCounter;
    uint256 start;

    constructor() public {
        admin = msg.sender;
        token = new ERC20("Turk Lirasi", "TL");
        ticketCounter = 0;
        start = block.timestamp;
    }

    fallback() external {
        revert();
    }

    function depositTL(uint amnt) public {
        //require(amnt <= token.balanceOf(msg.sender)); token implement etmis sanirim
        token.approve(msg.sender, amnt);
        if (token.transferFrom(msg.sender, address(this), amnt)) {
            balances[msg.sender] += amnt;
        }
    }

    
    function withdrawTL(uint amnt) public {
        require(amnt <= balances[msg.sender], "Not enough TL in the account");
        if (token.transferFrom(address(this), msg.sender, amnt)) {
            balances[msg.sender] -= amnt;
        }
    }

    function buyTicket(bytes32 hash_rnd_number) public {

        //we also need to check that current time is in the first 4 days of the lottery, otherwise, users should not not be able to buy tickets
        require(balances[msg.sender] >= 10, "Not enough TL in the account");
        balances[msg.sender] -= 10;
        Ticket curTicket = new Ticket(ticketCounter, msg.sender, hash_rnd_number);
        ticketsFromNo[ticketCounter] = curTicket;
        ticketsFromLottery[getLotteryNo((block.timestamp - start) / (60 * 60 * 24 * 7))][msg.sender].push(curTicket);
        ticketCounter += 1;
    }

    // does not implement an actual transfer, just update the user's account balance
    //suppose user got a ticket but did not reveal the rnd number during the reveal phase, then this refund will be applied
    function collectTicketRefund(uint ticket_no) public {
        require(ticket_no <= ticketCounter, "Ticket does not exist");
        Ticket refunded = ticketsFromNo[ticket_no];
        balances[refunded.ownerOf(ticket_no)] += 5;
    }


    //random number is revealed by users in reveal phase, be careful, do not reveal the hash
    function revealRndNumber(uint ticketno, uint rnd_number) public {
        
    }


    // last bought ticket for a specific person, status - for example someone has bought a ticket
    // but did not reveal it and it has been cancelled, or if the ticket has been transferred to
    // someone else, it can be 'no longer owned', don't delete the tickets until the lottery ends
    function getLastOwnedTicketNo(uint lottery_no) public view returns(uint, uint8 status) {

    }
    // again, for a specific person
    function getIthOwnedTicketNo(uint i, uint lottery_no) public view returns(uint, uint8 status) {
        return (ticketsFromLottery[lottery_no][msg.sender][i].ticketNo, ticketsFromLottery[lottery_no][msg.sender][i].status);
    }

    function checkIfTicketWon(uint ticket_no) public view returns (uint amount) {

    }

//here, the money earned by the lottery can be withdrawn after the lottery ends, not during the lottery period
    function collectTicketPrize(uint ticket_no) public {

    }

    function getIthWinningTicket(uint i, uint lottery_no) public view returns (uint ticket_no, uint amount) {
        
    }
    
    function getLotteryNo(uint unixtimeinweek) public view returns (uint lottery_no) {

    }

    function getTotalLotteryMoneyCollected(uint lottery_no) public view returns (uint amount) {

    }
    
}