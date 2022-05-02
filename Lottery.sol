// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./TL.sol";
import "./Ticket.sol";
import "../ethereum-api/oraclizeAPI_0.4.sol";
//import "http://github.com/oraclize/ethereum-api/oraclizeAPI_0.4.sol";

contract Lottery is usingOraclize {

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

// require conditionlarini modifier olarak tanimlamak lazim
*/
    // people
    address public admin;
    address payable[] public users;

    // payment
    TL public token;
    mapping(address => uint256) public balances;
    uint256[] public totalSupplies; // indexed by lottery_no

    // tickets
    uint256 public ticketCounter;
    mapping(uint256 => Ticket) public ticketsFromNo;
    mapping(uint256 => mapping(address => Ticket[])) public ticketsFromLottery;

    // time
    uint256 start;
    uint256 curLotStart;
    address alarm;

    // random numbers
    uint256[] public randomNumbers;    //bunu lottery bitişlerinde boşaltmak lazım
    mapping(uint => mapping(uint256 => uint256)) public ticketsFromRandoms; // maps to ticket_no
    mapping(uint => uint256[]) public winningTickets; // ticket_nos of winning tickets, bunu basta lottery_no ile indexleyip
    // iki boyutlu yapmak lazim gibi, cunku getIthWinningTicket fonksiyonu lottery_no da aliyor, ve
    // her lottery bittiginde yeni index eklemek lazim
    //tam bunu yazacaktım bro aynen ama bunu yaparsak ticket no dan lottery no ya erişebilmemiz de gerekecek.

    constructor() public {
        admin = msg.sender;
        token = new TL(10000000000000000000);
        ticketCounter = 0;
        start = block.timestamp;
        resetLottery(); // reset lottery schedule edilirse sil
    }

    fallback() external {
        revert();
    }

    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function depositTL(uint amnt) public {
        token.approve(msg.sender, amnt);
        if (token.transfer(address(this), amnt)) {
            balances[msg.sender] += amnt;
        }
    }

    
    function withdrawTL(uint amnt) public {
        require(amnt <= balances[msg.sender], "Not enough TL in the account");
        token.approve(msg.sender, amnt);
        if (token.send(address(this), msg.sender, amnt)) {
            balances[msg.sender] -= amnt;
        }
    }

    function buyTicket(bytes32 hash_rnd_number) public {
        require(block.timestamp - curLotStart < 4 days, "Lottery is not in purchase phase");
        require(balances[msg.sender] >= 10, "Not enough TL in the account");
        balances[msg.sender] -= 10;
        uint lotteryNo = getLotteryNo(block.timestamp / (1 weeks));
        Ticket curTicket = new Ticket(ticketCounter, msg.sender, hash_rnd_number, lotteryNo);
        ticketsFromNo[ticketCounter] = curTicket;
        ticketsFromLottery[lotteryNo][msg.sender].push(curTicket);
        ticketCounter += 1;
        totalSupplies[totalSupplies.length - 1] += 10;
    }

    // does not implement an actual transfer, just update the user's account balance
    //suppose user got a ticket but did not reveal the rnd number during the reveal phase, then this refund will be applied
    function collectTicketRefund(uint ticket_no) public {
        require(getLotteryNo(block.timestamp / (1 weeks)) > ticketsFromNo[ticket_no].getLotteryNo(), "Lottery is not finished yet");
        require(ticket_no < ticketCounter, "Ticket does not exist");
        require(ticketsFromNo[ticket_no].status() <= 1, "Ticket is not cancelled");
        Ticket refunded = ticketsFromNo[ticket_no];
        balances[refunded.getOwner()] += 5;
    }


    //random number is revealed by users in reveal phase, be careful, do not reveal the hash
    // if tickethash == hash(rnd_number), then add the random number with binding to the user for
    // calculating the winner number, also ticket status should be valid
    // else, ticket should be cancelled (bunlar benim gorusum bro eksik varsa haber et)
    function revealRndNumber(uint ticketno, uint rnd_number) public {
        require(getLotteryNo(block.timestamp / (1 weeks)) == ticketsFromNo[ticketno].getLotteryNo(), "Ticket is from other lottery");
        require(block.timestamp - curLotStart >= 4 days, "Lottery is not in reveal phase");
        require(ticketno < ticketCounter, "Ticket does not exist");
        Ticket ticket = ticketsFromNo[ticketno];
        uint lotteryNo = ticket.getLotteryNo();
        require(ticket.status() == 0, "Ticket is already revealed or cancelled");
        if (ticket.getHash_rnd_number() == keccak256(abi.encodePacked(rnd_number))) {
            randomNumbers.push(rnd_number);
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
        num -= 1;
        uint log = 0;
        while (num > 0) {
            num >>= 1;
            log += 1;
        }
        return log;
    }

    // bunu bence biz ekleyelim
    function selectWinners() public {
        // uses randomNumbers array to select random indexes, then gets the random numbers at these
        // indexes. After it fills winningTickers array using ticketsFromRandoms mapping.
        // first index at winningTickets should be first winner, second is the second winner ...
        /* random using n numbers, get the index, take it into the last element of the array
        the rest of the winners are selected using the random number of the previous winner
        */
        uint lotteryNo = getLotteryNo(block.timestamp / (1 weeks));
        uint nofWinners = ceilLog2(getTotalLotteryMoneyCollected(lotteryNo));
        if (nofWinners == 0) {
            return;
        }
        uint n = randomNumbers.length;
        uint sum = 0;
        uint xor = 0;
        for (uint i = 0; i < n; i++) {
            sum += randomNumbers[i];
            xor ^= randomNumbers[i];
        }
        uint index = (sum - xor) % n;
        winningTickets[lotteryNo].push(randomNumbers[index]);
        for (uint i = 0; i < nofWinners - 1; i++) { // check if ending condition is true
            (randomNumbers[index], randomNumbers[n - 1]) = (randomNumbers[n - 1], randomNumbers[index]);
            index = randomNumbers[n - 1 - i] % (n - 1 - i);
            winningTickets[lotteryNo].push(randomNumbers[index]);
        }
    }

    function calculatePrize(uint i, uint256 totalSupply) public pure returns (uint amount) { 
        return (totalSupply / (2**i)) + ((totalSupply / (2**(i - 1))) % 2); // does integer division, automatic flooring
    }

    // hoca winning ticketlar uzerinde looplayabilirsiniz cunku nasil olsa log M kadar baya kucuk demisti
    function checkIfTicketWon(uint ticket_no) public view returns (uint amount) {
        require(getLotteryNo(block.timestamp / (1 weeks)) > ticketsFromNo[ticket_no].getLotteryNo(), "Lottery is not finished yet");
        require(ticket_no < ticketCounter, "Ticket does not exist");
        Ticket ticket = ticketsFromNo[ticket_no];
        uint lotteryNo = ticket.getLotteryNo();
        for (uint i = 0; i < winningTickets[lotteryNo].length; i++) {
            if (winningTickets[lotteryNo][i] == ticket_no) {
                return calculatePrize(i + 1, totalSupplies[lotteryNo]);
            }
        }
        return 0;
    }

//here, the money earned by the lottery can be withdrawn after the lottery ends, not during the lottery period
    function collectTicketPrize(uint ticket_no) public {
        require(getLotteryNo(block.timestamp / (1 weeks)) > ticketsFromNo[ticket_no].getLotteryNo(), "Lottery is not finished yet");
        require(ticket_no < ticketCounter, "Ticket does not exist");
        require(ticketsFromNo[ticket_no].status() != 4, "Ticket prize has already been collected");
        uint256 amount = checkIfTicketWon(ticket_no);
        ticketsFromNo[ticket_no].setStatus(4);
        balances[ticketsFromNo[ticket_no].getOwner()] += amount;
    }

    // winningTickets 2 boyutlu olunca lottery_no ya gore indexlenecek, onun disinda bence dogru
    function getIthWinningTicket(uint i, uint lottery_no) public view returns (uint ticket_no, uint amount) {
        require(lottery_no <= getLotteryNo(block.timestamp / (1 weeks)), "Lottery is not finished yet");
        require(i > 0 && i <= ceilLog2(totalSupplies[getTotalLotteryMoneyCollected(lottery_no)]) + 1, "Ticket index out of bounds");
        return (winningTickets[lottery_no][i - 1], checkIfTicketWon(winningTickets[lottery_no][i - 1]));
    }
    
    function getLotteryNo(uint unixtimeinweek) public view returns (uint lottery_no) {
        // maybe we need to use start variable here also, like (time - start) in week format
        return unixtimeinweek - (start / (1 weeks)); // test et int geliyo mu
    }

    function getTotalLotteryMoneyCollected(uint lottery_no) public view returns (uint amount) {
        return totalSupplies[lottery_no];
    }

    function resetLottery() public {
        curLotStart = block.timestamp;
        uint currentLottery = getLotteryNo(block.timestamp / (1 weeks));
        totalSupplies.push(0);
        randomNumbers = new uint[](0);
        winningTickets[currentLottery] = new uint[](0);
    }

    function purchasePhase() {
        oraclize_query(4 days, "URL", "");
    }

    function revealPhase() {
        oraclize_query(3 days, "URL", "");
    }

    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()) {
            revert();
        }
        resetLottery();
        purchasePhase();
        selectWinners();
        revealPhase();
    }
    
}