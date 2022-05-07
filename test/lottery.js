
var Lottery = artifacts.require("Lottery");
const helper = require('../utils/utils.js');

contract("Lottery",(accounts) =>{   //bu çalışıyor mu bakmak lazım henüz deploylayamıyoruz bile
//accounts is given to access accounts in the current network
//hepsinde lotter initiate etmek yerine mocha frameworkü kurup (belki mochasız da çalışıyodur)
//const lottery = null;
    before(async () => {
        lottery = await Lottery.deployed();
    });
//before tüm testlerden önce uygulatır

    let randomNumbers = [];
    const counter = 5;

    it("Should deploy properly", async () =>{
        console.log(lottery.address);
        assert(lottery.address != '');
    });
    it("Should calculate prize correctly", async () =>{
        const result = await lottery.calculatePrize(1,3);
        assert(result == 2);
    });
    
    //bir array dönerse tüm elemanları big number olarak dönecek dolayısıyla map fonksiyonuyla onlara toNumber uygulayıp elde etmek lazımmış
    //contract blockunda uygulananlar birbrilerine bağlıdır. ilk testte bir arraye bir şey eklersen ikinci testte o eklediğin elemanı bulabilirsin.
    //assert(array === [1,2,3]); yanlış
    //assert.deepEqual(array, [1,2,3]); doğru
    //fonksiyon tuple dönüyorsa result[0], result[1] şeklinde değerleri alabilirsin
    //to test that a function reverts, use try catch

    it("Should not be able to collect ticket refund", async() =>{
        try{
            await lottery.collectTicketRefund(1, {from: accounts[1]});
        }
        catch(error){
            assert(error);
            return;
        }
        assert(false);
    })


    it("Deposit Tl correctly", async () => {
        // Get initial balances of first and second account.
        const account = accounts[0];
        const amount = 10;
        //const initialBalance = await web3.eth.getBalance(account);
        //const initialLotteryBalance = await web3.eth.getBalance(lottery.address);


        // Call the transfer function.
        await lottery.depositTL(amount, {from: account});   //burada account tarafından çağrıldıığını ifade edebiliyoruz.
        //{from: account, value: web3.utils.toWei('3','ether')}   defines msg.value = 3
    

        // Get balances after the transfer.
        //const finalBalance = await web3.eth.getBalance(account);
        //const finalLotteryBalance = await web3.eth.getBalance(lottery.address);   //bunlar nedense big number değil garip toNumber() çağrılmıyor

        // Test the effect of the transfer.
        //assert.equal(finalBalance.toNumber(), initialBalance.toNumber() - amount, "Amount wasn't correctly deposited to the account");
        //assert.equal(finalLotteryBalance.toNumber(), initialLotteryBalance.toNumber() + amount, "Amount wasn't correctly deposited to the contract");
        const balance = await lottery.balances.call(account); ///mappinge ulaşmak için
        assert.equal(balance.toNumber(), amount, "Amount wasn't correctly deposited to the account balance");
       
    });



    it("Should not be able to Withdraw Tl with that amount", async () => {
        // Get initial balances of first and second account.
        const account = accounts[0];
        const amount = 15;
        // Call the transfer function.
        
        try{
            await lottery.withdrawTL(amount, {from: account});   //burada account tarafından çağrıldıığını ifade edebiliyoruz.
        }
        catch(error){
            assert(error);
            return;
        }
        assert(false);
       
    });

    it("Should be able to top up balance and withdraw Tl ", async () => {
        // Get initial balances of first and second account.
        const account = accounts[0];
        const amount1 = 15;
        const amount2 = 10;

        await lottery.depositTL(amount1, {from: account}); 
        await lottery.withdrawTL(amount2, {from: account});   //burada account tarafından çağrıldıığını ifade edebiliyoruz.
        
        const balance = await lottery.balances.call(account); ///mappinge ulaşmak için
        assert.equal(balance.toNumber(), 10 + amount1 - amount2, "Amounts weren't correctly deposited and withdrawn from the account balance");
       
    });

    it("Should be able to buy ticket", async () => {
        const account = accounts[0];
        const initial_balance = await lottery.balances.call(account); ///mappinge ulaşmak için
        const rnd_number = 13;
        //const hashrndnumber =  keccak256(abi.encodePacked(rnd_number));
        const hashrndnumber = web3.utils.soliditySha3(rnd_number);
        await lottery.buyTicket(hashrndnumber, {from: account});
        const final_balance = await lottery.balances.call(account); ///mappinge ulaşmak için
        assert.equal(final_balance.toNumber() + 10, initial_balance.toNumber(), "Balance was not updated correctly after ticket purchase");
        const ticket_count = await lottery.ticketCounter();
        assert.equal(ticket_count.toNumber(), 1, "Ticket counter was not updated correctly after ticket purchase");
        const total_supply = await lottery.totalSupplies.call(0);
        assert.equal(total_supply.toNumber(), 10, "Total supply was not updated correctly after ticket purchase");
    })

    it("Multiple accounts should deposit tl and buy tickets", async () => {  //10 tane deneyebiliyoruz bçyle 100 nasıl olur?
        const amount = 20;

        for(let i = 1; i < counter; i++) {   //awaitsiz bir yol gozukmuyor, ama testi bir kere runlicaksak sorun yok 30 saniyede falan yapiyor
            account = accounts[i];
            await lottery.depositTL(amount, {from: account}); 
            const rnd_number = web3.utils.randomHex(32);
            const hashrndnumber = web3.utils.soliditySha3(rnd_number);
            await lottery.buyTicket(hashrndnumber, {from: account});
        }

        const ticket_count = await lottery.ticketCounter();
        assert.equal(ticket_count.toNumber(), counter, "Ticket counter was not updated correctly after ticket purchase");
        const total_supply = await lottery.totalSupplies.call(0);
        assert.equal(total_supply.toNumber(), 10 * counter, "Total supply was not updated correctly after ticket purchase");
    });

    it("Total lottery money should be correct", async () => {
        const lottery_no = 0;
        const supply = await lottery.getTotalLotteryMoneyCollected(lottery_no);
        assert(supply.toNumber() === 10 * counter, "Total lottery money was not correctly calculated");
    });

    it("Should not be able to reveal rnd number before reveal phase", async () => {
        const account = accounts[0];
        const rnd_number = web3.utils.randomHex(32);  //does not have to be same, we are not testing it yet
        const ticket_no = 0;
        try {
            await lottery.revealRndNumber(rnd_number, ticket_no, {from: account});
        }
        catch(error) {
            assert(error);
            return;
        }
        assert(false);
    })

    it("Should be able to reveal rnd number during reveal phase", async () => {
        advancement = 86400 * 5;
        await helper.advanceTimeAndBlock(advancement);
        //await web3.currentProvider.send({method: "evm_increaseTime", params: [60*60*24*5]});   //mock 5 days
        const account = accounts[0];
        const rnd_number = 13;  //the same random number
        const ticket_no = 0;
        await lottery.revealRndNumber(ticket_no, rnd_number, {from: account});  //ticket status should be set to 3 ama ticket does not exist hatası geliyor
        const result = await lottery.randomNumbers.call(0, 0);
        assert(result.toNumber() === rnd_number, "Random number was not correctly revealed");
    });

    it("Participants should be able to see ticket's winning prize", async () => {
        advancement = 86400 * 3;
        await helper.advanceTimeAndBlock(advancement);
        const ticket_no = 0;
        await lottery.checkIfTicketWon(ticket_no);
        const prize = await lottery.checkIfTicketWon.call(ticket_no); // division by zero hatasi var ama calculatePrizedan degil amk
        assert(prize.toNumber() == 25, "First winning prize was not correctly calculated");
    });

    it("Winner ticket numbers should be correctd returned", async () => {
        const ticket_no = 0;
        const prize = 25;
        await lottery.getIthWinningTicket(1, 0);
        const results = await lottery.getIthWinningTicket.call(1, 0);
        assert(ticket_no == results['0'].toNumber(), "Ticket numbers were not correctly returned");
        assert(prize == results['1'].toNumber(), "Prizes were not correctly returned");
    })

    it("Owner of a winner ticket should be able to obtain their prize", async () => {
        const account = accounts[0];
        const ticket_no = 0;
        await lottery.collectTicketPrize(ticket_no);
        const balance = await lottery.balances.call(account);
        assert(balance.toNumber() == 30, "Prize was not correctly collected"); // onceki testten 5 kalmis, istersen bunu baska hesapla yapalim lotteryi buyutup
    })

    it("Not correctly revealed tickets could be refunded", async () => {
        const ticket_no = 1;
        const account = accounts[1];
        await lottery.collectTicketRefund(ticket_no);
        const balance = await lottery.balances.call(account);
        assert(balance.toNumber() == 15, "Refund was not correctly collected");
    });

    it("Should be able to get owned tickets", async () => {
        const account = accounts[2];
        const lottery_no = 0;
        const results = await lottery.getIthOwnedTicketNo(1, lottery_no, {from: account});
        assert(results['0'].toNumber() == 2, "Ticket numbers were not correctly returned");
        assert(results['1'].toNumber() == 0, "Prizes were not correctly returned");
    }); 
});



