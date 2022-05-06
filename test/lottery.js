
var Lottery = artifacts.require("Lottery");
const helper = require('../utils/utils.js');

contract("Lottery",(accounts) =>{   //bu çalışıyor mu bakmak lazım henüz deploylayamıyoruz bile
//accounts is given to access accounts in the current network
//hepsinde lotter initiate etmek yerine mocha frameworkü kurup (belki mochasız da çalışıyodur)
//const lottery = null;
//before(async()=>{
//    lottery = await Lottery.deployed();
//});
//before tüm testlerden önce uygulatır


    it("Should deploy properly", async () =>{
        const lottery = await Lottery.deployed();
        console.log(lottery.address);
        assert(lottery.address != '');
    });
    it("Should calculate prize correctly", async () =>{
        const lottery = await Lottery.deployed();
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
        const lottery = await Lottery.deployed();
        
        try{
            await lottery.collectTicketRefund(1,{from: accounts[1]});
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
        const lottery = await Lottery.deployed();
        const amount = 10;
        const initialBalance = await web3.eth.getBalance(account);
        const initialLotteryBalance = await web3.eth.getBalance(lottery.address);


        // Call the transfer function.
        await lottery.depositTL(amount, {from: account});   //burada account tarafından çağrıldıığını ifade edebiliyoruz.
        //{from: account, value: web3.utils.toWei('3','ether')}   defines msg.value = 3
    

        // Get balances after the transfer.
        const finalBalance = await web3.eth.getBalance(account);
        const finalLotteryBalance = await web3.eth.getBalance(lottery.address);   //bunlar nedense big number değil garip toNumber() çağrılmıyor

        // Test the effect of the transfer.
        //assert.equal(finalBalance.toNumber(), initialBalance.toNumber() - amount, "Amount wasn't correctly deposited to the account");
        //assert.equal(finalLotteryBalance.toNumber(), initialLotteryBalance.toNumber() + amount, "Amount wasn't correctly deposited to the contract");
        const balance = await lottery.balances.call(account); ///mappinge ulaşmak için
        assert.equal(balance.toNumber(), amount, "Amount wasn't correctly deposited to the account balance");
       
    });



    it("Should not be able to Withdraw Tl with that amount", async () => {
        // Get initial balances of first and second account.
        const account = accounts[0];
        const lottery = await Lottery.deployed();
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
        const lottery = await Lottery.deployed();
        const amount1 = 15;
        const amount2 = 10;


        await lottery.depositTL(amount1, {from: account}); 
        await lottery.withdrawTL(amount2, {from: account});   //burada account tarafından çağrıldıığını ifade edebiliyoruz.
        
        const balance = await lottery.balances.call(account); ///mappinge ulaşmak için
        assert.equal(balance.toNumber(), 10 + amount1 - amount2, "Amounts weren't correctly deposited and withdrawn from the account balance");
       
    });

    it("Should be able to buy ticket", async () => {
        const account = accounts[0];
        const lottery = await Lottery.deployed();
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
        const lottery = await Lottery.deployed();
        const amount = 20;
        

        for(let i = 1; i<10; i++){   //böyle yaptım ama birbirleirni bekliyor gibiler uzun sürüyor sorun olur mu? mesela 1000 account çok vakit alır
            account = accounts[i];
            await lottery.depositTL(amount, {from: account}); 
            const rnd_number = web3.utils.randomHex(32);
            const hashrndnumber = web3.utils.soliditySha3(rnd_number);
            await lottery.buyTicket(hashrndnumber, {from: account});
        }

        const ticket_count = await lottery.ticketCounter();
        assert.equal(ticket_count.toNumber(), 10, "Ticket counter was not updated correctly after ticket purchase");
        const total_supply = await lottery.totalSupplies.call(0);
        assert.equal(total_supply.toNumber(), 100, "Total supply was not updated correctly after ticket purchase");
    });

    it("Should not be able to reveal rnd number before reveal phase", async () => {
        const account = accounts[0];
        const lottery = await Lottery.deployed();
        const rnd_number = web3.utils.randomHex(32);  //does not have to be same, we are not testing it yet
        const ticket_no = 0;
        try{
            await lottery.revealRndNumber(rnd_number, ticket_no, {from: account});
        }
        catch(error){
            assert(error);
            return;
        }
        assert(false);
    })

    it("Should be able to reveal rnd number during reveal phase", async () => {
        advancement = 86400 * 5 // 10 Days
        await helper.advanceTimeAndBlock(advancement)
        //await web3.currentProvider.send({method: "evm_increaseTime", params: [60*60*24*5]});   //mock 5 days
        const account = accounts[0];
        const lottery = await Lottery.deployed();
        const rnd_number = 13;  //the same random number
        const ticket_no = 0;
        const ticket_count = await lottery.ticketCounter();
        console.log(ticket_count);
        await lottery.revealRndNumber(rnd_number, ticket_no, {from: account});  //ticket status should be set to 3 ama ticket does not exist hatası geliyor
        console.log("done");
        const ticket = await lottery.ticketsFromNo(ticket_no);
        const ticket_status = await ticket.status();
        console.log(ticket_status);
        assert(ticket_status.toNumber() == 3, "Ticket status was not set to 3");
    });

    
});



