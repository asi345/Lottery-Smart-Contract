
var Lottery = artifacts.require("Lottery");
const helper = require('../utils/utils.js');


contract("Lottery",(accounts) =>{
    before(async () => {
        lottery = await Lottery.deployed();
    });

    let randomNumbers = [];
    const counter = 5;

    it("Should deploy properly", async () =>{
        console.log(lottery.address);
        console.log(lottery.receipt);
        assert(lottery.address != '');
    });
    it("Should calculate prize correctly", async () =>{
        const result = await lottery.calculatePrize(1,3);
        assert(result == 2);
    });

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


contract("Lottery",(accounts) =>{   //bu çalışıyor mu bakmak lazım henüz deploylayamıyoruz bile
    //accounts is given to access accounts in the current network
    //hepsinde lotter initiate etmek yerine mocha frameworkü kurup (belki mochasız da çalışıyodur)
    //const lottery = null;
        before(async () => {
            lottery = await Lottery.deployed();
        });
    //before tüm testlerden önce uygulatır
    
        let randomNumbers = [];
        let hashrandoms = [];
        const counter = 20;
        const amount = 30;
        it("Should deploy properly", async () =>{
            console.log(lottery.address);
            assert(lottery.address != '');
        });

        it("Deposit Tl and buy ticket correctly with multiple accounts", async () => {
            // Get initial balances of first and second account.
            
            for(let i = 0; i< counter; i++) {
                const account = accounts[i];
                await lottery.depositTL(amount, {from: account});   //burada account tarafından çağrıldıığını ifade edebiliyoruz.
                const rnd_number = web3.utils.randomHex(32);
                randomNumbers.push(rnd_number);
                const hashrndnumber = web3.utils.soliditySha3(rnd_number);
                hashrandoms.push(hashrndnumber);
                await lottery.buyTicket(hashrndnumber, {from: account});
            }
            for(let i = 0; i< counter; i++) {
                const balance = await lottery.balances.call(accounts[i]); ///mappinge ulaşmak için
                assert.equal(balance.toNumber(), amount-10, "Amount wasn't correctly deposited to the account balance");
            }
            const ticket_count = await lottery.ticketCounter();
            assert.equal(ticket_count.toNumber(), counter, "Ticket counter was not updated correctly after ticket purchase");
            const total_supply = await lottery.totalSupplies.call(0);
            assert.equal(total_supply.toNumber(), 10 * counter, "Total supply was not updated correctly after ticket purchase");

        });

        it("Checking the revealed random numbers correctly", async () => {  //hata var
            advancement = 86400 * 6;
            await helper.advanceTimeAndBlock(advancement);

            for(let i = 0; i< counter/2; i++) {   //half of them will reveal correct random numbers
                const account = accounts[i];
                const rnd_number = randomNumbers[i];
                await lottery.revealRndNumber(i, rnd_number, {from: account});
            }
            for(let i = counter/2; i< counter; i++) {   //half of them will reveal wrong random numbers
                const account = accounts[i];
                const rnd_number = web3.utils.randomHex(32);
                await lottery.revealRndNumber(i, rnd_number, {from: account});
            }


            for(let i = 0; i< counter/2; i++) {
                const random_in_lottery = await lottery.randomNumbers.call(0,i);  //her bir eleman bir array gibi dönüyor
                //assert(random_in_lottery.isEqualTo(web3.utils.toBN(randomNumbers[i])), "Random number was not correctly revealed");
                expect(random_in_lottery).to.eql(web3.utils.toBN(randomNumbers[i]));
            }
            try{
                for(let i = counter/2; i< counter; i++) {
                    const random_in_lottery = await lottery.randomNumbers.call(0,i);  //her bir eleman bir array gibi dönüyor
                    //assert(random_in_lottery.isEqualTo(web3.utils.toBN(randomNumbers[i])), "Random number was not correctly revealed");
                    expect(random_in_lottery).to.eql(web3.utils.toBN(randomNumbers[i]));
                }
            } 
            catch(e){
                assert(e);
                return;
            }
            assert(false, "Wrong random numbers should not be pushed");
        });

        it("Participants should be able to see ticket's winning prize and collect it", async () => {
            advancement = 86400 * 3;
            await helper.advanceTimeAndBlock(advancement);

            for(let i = 0; i< counter/2; i++) {
                const ticket_no = i;
                await lottery.checkIfTicketWon(ticket_no);   //arithmetic overflow
                const prize = await lottery.checkIfTicketWon.call(ticket_no); // division by zero hatasi var ama calculatePrizedan degil amk
               
                await lottery.collectTicketPrize(ticket_no);
                const balance = await lottery.balances.call(accounts[i]);
              
                assert(balance.toNumber() == 20 + prize.toNumber(), "Prize was not correctly collected"); // onceki testten 5 kalmis, istersen bunu baska hesapla yapalim lotteryi buyutup
    
            }
            
        });

        it("Refunding tickets can only be done by the last half of participants", async () => {
            try{
                await lottery.collectTicketRefund(2);
                await lottery.collectTicketRefund(7);
            }
            catch(e){
                assert(e);
                return;
            }
            assert(false, "Refund should not be done");
        })

        it("Participants with wrong reveal can refund tickets", async () => {
            for(let i = counter/2; i< counter; i++) {
                const ticket_no = i;

                //const status = await lottery.getTicketStatus(ticket_no);
                //console.log(status);  ticket statusu böyle görebiliriz sonra silelim.
                await lottery.collectTicketRefund(ticket_no);
                const balance = await lottery.balances.call(accounts[i]);
                assert(balance.toNumber() == amount - 5, "Refund was not correctly collected");
            }
            
        })

        it("Winner ticket numbers should be correctd returned", async () => {

            const total_supply = await lottery.totalSupplies.call(0);
            var winnercount = await lottery.ceilLog2(total_supply);
            var winnercount_num = winnercount.toNumber();
            winnercount_num += 1;
            //console.log(winnercount_num);
            var last = total_supply.toNumber();
            for(let i = 1; i<=winnercount ; i++) {
                const results = await lottery.getIthWinningTicket.call(i, 0);
                const ticket_no = results[0].toNumber();
                const prize_from_lottery = results[1].toNumber();
                await lottery.checkIfTicketWon(ticket_no);
                const prize = await lottery.checkIfTicketWon.call(ticket_no);
                assert(prize_from_lottery == prize.toNumber(), "Prizes from two functions are inconsistent");
                assert(last > prize.toNumber(), "Prizes are not sorted");
                last = prize.toNumber();
            }
        })
       

        //we will be in lottery with no 1
        it("Participants will get multiple tickets if they win multiple times", async () => {
            randomNumbers = [];
            hashrandoms = [];
            for(let i = 0; i< counter; i++) {
                const account = accounts[i];
                await lottery.depositTL(amount, {from: account});   //burada account tarafından çağrıldıığını ifade edebiliyoruz.
                for(let j = 0; j< 3; j++) {  //buy 3 tickets (10,11,12 -> accounts[0]  13,14,15 -> accounts[1]  16,17,18 -> accounts[2]...)
                    const rnd_number = web3.utils.randomHex(32);
                    randomNumbers.push(rnd_number);
                    const hashrndnumber = web3.utils.soliditySha3(rnd_number);
                    hashrandoms.push(hashrndnumber);
                    await lottery.buyTicket(hashrndnumber, {from: account});
                }
            }

        })


        it("Should be able to see ith owned ticket", async () => {

            var account_no = 3
            var i = 2
            const result = await lottery.getIthOwnedTicketNo(i,1,{from: accounts[account_no]});
            const ticket_no = result[0].toNumber();
            const status = result[1].toNumber();
            const expected_ticket_no = counter + account_no*3 + i - 1;
            const expected_status = 0;
            assert(ticket_no == expected_ticket_no, "Ticket number is not correct");
            assert(status == expected_status, "Status is not correct");
        })


        it("Should not be able to see ith owned ticket in a wrong lottery or out of index", async () => {

            var account_no = 3;
            var lottery_no = 4;
            var i = 2
            try{
                const result = await lottery.getIthOwnedTicketNo(i,lottery_no,{from: accounts[account_no]});
            }
            catch(e){
                assert(e);
                return;
            }
            assert(false, "Should not be able to see ith owned ticket in a wrong lottery");

        })

        it("Should not be able to see ith owned ticket in a wrong lottery or out of index", async () => {

            var account_no = 2;
            var lottery_no = 1;
            var i = 6;
            try{
                const result = await lottery.getIthOwnedTicketNo(i,lottery_no,{from: accounts[account_no]});
            }
            catch(e){
                assert(e);
                return;
            }
            assert(false, "Should not be able to see ith owned ticket with a wrong i");

        })
        
        //26 days later from the start: lottery no: 3 reveal phase
        it("Should not be able to reveal random number in a wrong lottery", async () => {
            advancement = 86400 * 17;
            await helper.advanceTimeAndBlock(advancement);

            for(let i = 0; i< counter; i++) {   //half of them will reveal correct random numbers
                const account = accounts[i];
                for(let j = 0; j< 3; j++) {
                    const rnd_number = randomNumbers[i*3 + j];
                    try{
                        await lottery.revealRndNumber(counter + i*3 + j, rnd_number, {from: account});
                    }
                    catch(e){
                        assert(e);
                        return;
                    }
                    assert(false, "Should not be able to reveal random number in a wrong lottery");
                }
            }
        })
        it("Should not be able to buy ticket in the reveal phase", async () => {
            
            var account_no = 4;
            const account = accounts[account_no];

            try{
                const rnd_number = web3.utils.randomHex(32);
                const hashrndnumber = web3.utils.soliditySha3(rnd_number);
                await lottery.buyTicket(hashrndnumber, {from: account});
            }
            catch(e){
                assert(e);
                return;
            }
            assert(false, "Should not be able to buy ticket in the reveal phase");
        })

        it("Should be able to collect ticket refund after weeks", async () => {
            for(let i = 0; i< counter; i++) {   
                const account = accounts[i];
                const balance1 = await lottery.balances.call(account);
                for(let j = 0; j< 3; j++) {
                    await lottery.collectTicketRefund(counter + i*3 + j);
                }
                const balance2 = await lottery.balances.call(account);
                assert(balance1.toNumber() == balance2.toNumber() - 15, "Refund was not correctly collected");
            }
        })
    
});
