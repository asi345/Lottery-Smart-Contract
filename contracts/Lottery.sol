// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./TL.sol";
import "./Ticket.sol";

contract Lottery{

/*
users will provide the random numberss
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

// mappings can be seen as hash tables which are virtually initialized such that every possible
// key exists and is mapped to a value whose byte-representation are all zeros
*/
    // people
    //address public admin;
    address payable[] public users;

    // payment
    TL public token = new TL(10000);
    mapping(address => uint256) public balances;
    mapping(uint256 => uint256) public totalSupplies; // key is lottery_no

    // tickets
    uint256 public ticketCounter = 0;
    mapping(uint256 => Ticket) public ticketsFromNo;
    mapping(uint256 => mapping(address => Ticket[])) public ticketsFromLottery;

    // time
    uint256 public start;
    mapping(uint256 => uint8) public isSelected; // whether winners are chosen for the lotteries, key is lottery_no
    uint timeUnitWeek = 1 minutes;

    // random numbers
    mapping(uint256 => uint256[]) public randomNumbers; // key is lottery_no
    mapping(uint => mapping(uint256 => uint256)) public ticketsFromRandoms; // maps to ticket_no
    mapping(uint => uint256[]) public winningTickets; // ticket_nos of winning tickets, key is lottery_no

    event lotMoney(uint amnt); // delete later, just for testing

    modifier lotteryFinished (uint ticket_no){
        require(getLotteryNoBySec(block.timestamp) > ticketsFromNo[ticket_no].getLotteryNo(), "Lottery is not finished yet");
        _;
    }

    modifier ticketExists (uint ticket_no){
        require(ticket_no < ticketCounter, "Ticket does not exist");
        _;
    }

//nasıl run out of gas?!
    constructor() public {
        start = block.timestamp;
    }

    fallback() external {
        revert();
    }

    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function depositTL(uint amnt) public {
        if (token.transfer(address(this), amnt)) {
            balances[msg.sender] += amnt;
        }
    }

    
    function withdrawTL(uint amnt) public {
        require(amnt <= balances[msg.sender], "Not enough TL in the account");
        if (token.send(address(this), msg.sender, amnt)) {
            balances[msg.sender] -= amnt;
        }
    }

    function buyTicket(bytes32 hash_rnd_number) public {
        uint lotteryNo = getLotteryNoBySec(block.timestamp);
        require(block.timestamp - start - (1 weeks) * lotteryNo < 4 days, "Lottery is not in purchase phase");
        require(balances[msg.sender] >= 10, "Not enough TL in the account");
        balances[msg.sender] -= 10;
        Ticket curTicket = new Ticket(ticketCounter, msg.sender, hash_rnd_number, lotteryNo);
        ticketsFromNo[ticketCounter] = curTicket;
        ticketsFromLottery[lotteryNo][msg.sender].push(curTicket);
        ticketCounter += 1;
        totalSupplies[lotteryNo] += 10;
    }

    // does not implement an actual transfer, just update the user's account balance
    //suppose user got a ticket but did not reveal the rnd number during the reveal phase, then this refund will be applied
    function collectTicketRefund(uint ticket_no) public lotteryFinished(ticket_no) ticketExists(ticket_no) {
        require(ticketsFromNo[ticket_no].status() <= 1, "Ticket is not cancelled");
        Ticket refunded = ticketsFromNo[ticket_no];
        balances[refunded.getOwner()] += 5;
    }

    //random number is revealed by users in reveal phase, be careful, do not reveal the hash
    // if tickethash == hash(rnd_number), then add the random number with binding to the user for
    // calculating the winner number, also ticket status should be valid
    // else, ticket should be cancelled (bunlar benim gorusum bro eksik varsa haber et)
    function revealRndNumber(uint ticketno, uint rnd_number) public ticketExists(ticketno) {
        Ticket ticket = ticketsFromNo[ticketno];
        uint lotteryNo = ticket.getLotteryNo();
        require(getLotteryNoBySec(block.timestamp) == lotteryNo, "Ticket is from other lottery");
        require(block.timestamp - (1 weeks) * lotteryNo >= 4 days, "Lottery is not in reveal phase");
        require(ticket.status() == 0, "Ticket is already revealed or cancelled");
        if (ticket.getHash_rnd_number() == keccak256(abi.encodePacked(rnd_number))) {
            randomNumbers[lotteryNo].push(rnd_number);
            ticketsFromRandoms[lotteryNo][rnd_number] = ticketno;
            ticket.setStatus(3);
        } else {
            ticket.setStatus(1);   //hash tutmayınca cancelled demek doğru mu?, adam bu fonksiyonu hiç çağırmazsa da cancelled yapmamız gerekecek
        }
    }

    // last bought ticket for a specific person, status - for example someone has bought a ticket
    // but did not reveal it and it has been cancelled, or if the ticket has been transferred to
    // someone else, it can be 'no longer owned', don't delete the tickets until the lottery ends
    function getLastOwnedTicketNo(uint lottery_no) public view returns(uint, uint8 status) {
        uint i = ticketsFromLottery[lottery_no][msg.sender].length - 1;
        require(i >= 0, "No ticket bought");
        return (ticketsFromLottery[lottery_no][msg.sender][i].getTicketNo(),
            ticketsFromLottery[lottery_no][msg.sender][i].status());
    }

    function getIthOwnedTicketNo(uint i, uint lottery_no) public view returns(uint, uint8 status) {
        require(i > 0 && i <= ticketsFromLottery[lottery_no][msg.sender].length, "Ticket index out of bounds");
        return (ticketsFromLottery[lottery_no][msg.sender][i - 1].getTicketNo(),
            ticketsFromLottery[lottery_no][msg.sender][i - 1].status());
    }

    function ceilLog2(uint num) public pure returns (uint) {
        /*num -= 1;
        uint log = 0;
        while (num > 0) {
            num /= 2;
            log += 1;
        }
        return log;*/
        num -= 1;
        uint x = num;
        uint n = 0;
        if (x >= 2**128) { x >>= 128; n += 128; }
        if (x >= 2**64) { x >>= 64; n += 64; }
        if (x >= 2**32) { x >>= 32; n += 32; }
        if (x >= 2**16) { x >>= 16; n += 16; }
        if (x >= 2**8) { x >>= 8; n += 8; }
        if (x >= 2**4) { x >>= 4; n += 4; }
        if (x >= 2**2) { x >>= 2; n += 2; }
        if (x >= 2**1) { /* x >>= 1; */ n += 1; }
        n += 1;
        return n;
    }

    function selectWinners(uint lotteryNo) public {
        // uses randomNumbers array to select random indexes, then gets the random numbers at these
        // indexes. After it fills winningTickers array using ticketsFromRandoms mapping.
        // first index at winningTickets should be first winner, second is the second winner ...
        /* random using n numbers, get the index, take it into the last element of the array
        the rest of the winners are selected using the random number of the previous winner
        */
        emit lotMoney(getTotalLotteryMoneyCollected(lotteryNo));
        uint nofWinners = ceilLog2(getTotalLotteryMoneyCollected(lotteryNo)) + 1;
        if (nofWinners == 0) {
            return;
        }
        uint n = randomNumbers[lotteryNo].length;
        uint sum = 0;
        uint xor = 0;
        for (uint i = 0; i < n; i++) {
            sum += randomNumbers[lotteryNo][i];
            xor ^= randomNumbers[lotteryNo][i];
        }
        uint index = (sum - xor) % n;
        winningTickets[lotteryNo].push(ticketsFromRandoms[lotteryNo][randomNumbers[lotteryNo][index]]);
        uint loopCount = nofWinners < n ? nofWinners: n;
        for (uint i = 0; i < loopCount - 1; i++) { // check if ending condition is true
            (randomNumbers[lotteryNo][index], randomNumbers[lotteryNo][n - 1]) =
                (randomNumbers[lotteryNo][n - 1], randomNumbers[lotteryNo][index]);
            index = randomNumbers[lotteryNo][n - 1 - i] % (n - 1 - i);   //çok sağlam bir kıstas mı acaba
            winningTickets[lotteryNo].push(ticketsFromRandoms[lotteryNo][randomNumbers[lotteryNo][index]]);
        }
    }

    function ensureResults(uint lottery_no) public {
        if (isSelected[lottery_no] == 0) {
            selectWinners(lottery_no);
            isSelected[lottery_no] = 1;
        }
    }

    function calculatePrize(uint i, uint256 totalSupply) public pure returns (uint amount) { 
        return (totalSupply / (2**i)) + ((totalSupply / (2**(i - 1))) % 2); // does integer division, automatic flooring
    }

    // hoca winning ticketlar uzerinde looplayabilirsiniz cunku nasil olsa log M kadar baya kucuk demisti
    function checkIfTicketWon(uint ticket_no) public ticketExists(ticket_no) lotteryFinished(ticket_no) returns (uint amount) {
        Ticket ticket = ticketsFromNo[ticket_no];
        uint lotteryNo = ticket.getLotteryNo();
        ensureResults(lotteryNo);
        for (uint i = 0; i < winningTickets[lotteryNo].length; i++) {
            if (winningTickets[lotteryNo][i] == ticket_no) {
                return calculatePrize(i + 1, totalSupplies[lotteryNo]);
            }
        }
        return 0;
    }

//here, the money earned by the lottery can be withdrawn after the lottery ends, not during the lottery period
    function collectTicketPrize(uint ticket_no) public ticketExists(ticket_no) lotteryFinished(ticket_no) {
        require(ticketsFromNo[ticket_no].status() != 4, "Ticket prize has already been collected");
        ensureResults(ticketsFromNo[ticket_no].getLotteryNo());
        uint256 amount = checkIfTicketWon(ticket_no);
        ticketsFromNo[ticket_no].setStatus(4);
        balances[ticketsFromNo[ticket_no].getOwner()] += amount;
    }

    // winningTickets 2 boyutlu olunca lottery_no ya gore indexlenecek, onun disinda bence dogru
    function getIthWinningTicket(uint i, uint lottery_no) public returns (uint ticket_no, uint amount) {
        require(lottery_no <= getLotteryNoBySec(block.timestamp), "Lottery is not finished yet");
        require(i > 0 && i <= ceilLog2(getTotalLotteryMoneyCollected(lottery_no)) + 1, "Ticket index out of bounds or ticket has not won");
        ensureResults(lottery_no);
        return (winningTickets[lottery_no][i - 1], checkIfTicketWon(winningTickets[lottery_no][i - 1]));
    }
    
    function getLotteryNo(uint unixtimeinweek) public view returns (uint lottery_no) {
        return unixtimeinweek - (start / (1 weeks));
    }

    function getLotteryNoBySec(uint unixtimeinsec) public view returns (uint lottery_no) {
        return (unixtimeinsec - start) / (1 weeks);
    }

    function getTotalLotteryMoneyCollected(uint lottery_no) public view returns (uint amount) {
        return totalSupplies[lottery_no];
    }

    function getTime() public view returns (uint unixtime) {
        return block.timestamp;
    }
   
}