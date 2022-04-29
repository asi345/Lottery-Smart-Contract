// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./TL.sol";
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

// zamani simule etmek lazim, nasil bakalim
// autonomous calismasi icin bu fonksiyonlari cagiran bir contract daha gerekebilir, cunku
// biz manuel winner secme fonksiyonunu cagirmazsak nasil winner secilcek
*/
    // people
    address public admin;
    address payable[] public users;

    // payment
    TL public token;
    mapping(address => uint256) public balances;
    uint256[] public totalSupplies; //indexed by lottery_no

    // tickets
    uint256 public ticketCounter;
    mapping(uint256 => Ticket) public ticketsFromNo;
    mapping(uint256 => mapping(address => Ticket[])) public ticketsFromLottery;

    // time
    uint256 start;

    // random numbers
    uint256[] public randomNumbers;
    mapping(uint256 => uint256) ticketsFromRandoms; // maps to ticket_no
    // Ticket buyuk bir yapi, her lotteryde bir suru ticket eklencek ticketnoya maplemek mantikli geldi
    uint256[] public winningTickets; // ticket_nos of winning tickets, bunu basta lottery_no ile indexleyip
    // iki boyutlu yapmak lazim gibi, cunku getIthWinningTicket fonksiyonu lottery_no da aliyor
    // ama her lottery bittiginde yeni index eklemek lazim

    constructor() public {
        admin = msg.sender;
        token = new TL(10000000000000000000);
        ticketCounter = 0;
        start = block.timestamp;
    }

    fallback() external {
        revert();
    }

    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
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
        //lottery period bittiginde yeni index acilmali burada, time bakarken dikkat et
        totalSupplies[totalSupplies.length - 1] += 10;
    }

    // does not implement an actual transfer, just update the user's account balance
    //suppose user got a ticket but did not reveal the rnd number during the reveal phase, then this refund will be applied
    function collectTicketRefund(uint ticket_no) public {
        require(ticket_no <= ticketCounter, "Ticket does not exist");
        require(ticketsFromNo[ticket_no].status() <= 1, "Ticket is not cancelled");
        Ticket refunded = ticketsFromNo[ticket_no];
        balances[refunded.getOwner()] += 5;
    }


    //random number is revealed by users in reveal phase, be careful, do not reveal the hash
    // if tickethash == hash(rnd_number), then add the random number with binding to the user for
    // calculating the winner number, also ticket status should be valid
    // else, ticket should be cancelled (bunlar benim gorusum bro eksik varsa haber et)
    function revealRndNumber(uint ticketno, uint rnd_number) public {
        require(ticketno <= ticketCounter, "Ticket does not exist");
        Ticket ticket = ticketsFromNo[ticketno];
        // require(ticket.status == 0, "Ticket is not purchased"); boyle bir sey gerekebilir
        require(ticket.status() == 0, "Ticket is already revealed or cancelled");
        if (ticket.getHash_rnd_number() == keccak256(abi.encodePacked(rnd_number))) {
            randomNumbers.push(rnd_number);
            ticketsFromRandoms[rnd_number] = ticketno;
            ticket.setStatus(3);
        } else {
            ticket.setStatus(1);
        }
    }


    // last bought ticket for a specific person, status - for example someone has bought a ticket
    // but did not reveal it and it has been cancelled, or if the ticket has been transferred to
    // someone else, it can be 'no longer owned', don't delete the tickets until the lottery ends
    function getLastOwnedTicketNo(uint lottery_no) public view returns(uint, uint8 status) {
        uint i = ticketsFromLottery[lottery_no][msg.sender].length - 1;
        return (ticketsFromLottery[lottery_no][msg.sender][i].getTicketNo(),
            ticketsFromLottery[lottery_no][msg.sender][i].status());
    }

    // again, for a specific person
    function getIthOwnedTicketNo(uint i, uint lottery_no) public view returns(uint, uint8 status) {
        require(i < ticketsFromLottery[lottery_no][msg.sender].length, "Ticket index out of bounds");
        return (ticketsFromLottery[lottery_no][msg.sender][i].getTicketNo(),
            ticketsFromLottery[lottery_no][msg.sender][i].status());
    }

    // bunu bence biz ekleyelim
    function selectWinners() public {
        // uses randomNumbers array to select random indexes, then gets the random numbers at these
        // indexes. After it fills winningTickers array using ticketsFromRandoms mapping.
        // first index at winningTickets should be first winner, second is the second winner ...
    }

    function calculatePrize(uint i, uint256 totalSupply) public pure returns (uint amount) { 
        return (totalSupply / (2**i)) + ((totalSupply / (2**(i - 1))) % 2); // does integer division, automatic flooring
    }

    // hoca winning ticketlar uzerinde looplayabilirsiniz cunku nasil olsa log M kadar baya kucuk demisti
    function checkIfTicketWon(uint ticket_no) public view returns (uint amount) {
        // favors mapping ticket => i where i is ith winning
        for (uint i = 0; i < winningTickets.length; i++) {
            if (winningTickets[i] == ticket_no) {
                // altta bence son indexi versek okey ama yoksa getTotalLoetteryMoneyCollected kullanalim mi bir bak
                return calculatePrize(i + 1, totalSupplies[totalSupplies.length - 1]);
            }
        }
        return 0;
    }

//here, the money earned by the lottery can be withdrawn after the lottery ends, not during the lottery period
    function collectTicketPrize(uint ticket_no) public {
        // require(); check the time
        uint256 amount = checkIfTicketWon(ticket_no);
        balances[ticketsFromNo[ticket_no].getOwner()] += amount;
    }

    // winningTickets 2 boyutlu olunca lottery_no ya gore indexlenecek, onun disinda bence dogru
    function getIthWinningTicket(uint i, uint lottery_no) public view returns (uint ticket_no, uint amount) {
        require(i > 0, "Ticket index out of bounds");
        // log implement etmek lazim pure function olarak
        //require(i <= log(totalSupplies[getTotalLotteryMoneyCollected(lottery_no)]) + 1, "Ticket index out of bounds");
        return (winningTickets[i], checkIfTicketWon(winningTickets[i]));
    }
    
    function getLotteryNo(uint unixtimeinweek) public view returns (uint lottery_no) {

    }

    function getTotalLotteryMoneyCollected(uint lottery_no) public view returns (uint amount) {
        return totalSupplies[lottery_no];
    }
    
}