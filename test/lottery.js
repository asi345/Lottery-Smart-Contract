
var Lottery = artifacts.require("./Lottery.sol");


contract("Lottery", accounts => {
    it("Deposit Tl correctly", async () => {
        // Get initial balances of first and second account.
        const account = accounts[0];
        const lottery = await Lottery.deployed();
        const amount = 10;
        const initialBalance = await web3.eth.getBalance(account);
        const initialLotteryBalance = await web3.eth.getBalance(lottery.address);

        // Call the transfer function.
        await lottery.deposit(amount, {from: account});
        account.call{gas: 1000000}(abi.encodeWithSignature("DepositTl(uint)", 15))  //hesabın deposit tl çaırmasını sağlamak lazım
    ;

        // Get balances after the transfer.
        const finalBalance = await web3.eth.getBalance(account);
        const finalLotteryBalance = await web3.eth.getBalance(lottery.address);

        // Test the effect of the transfer.
        assert.equal(finalBalance.toNumber(), initialBalance.toNumber() - amount, "Amount wasn't correctly deposited to the account");
        assert.equal(finalLotteryBalance.toNumber(), initialLotteryBalance.toNumber() + amount, "Amount wasn't correctly deposited to the contract");
    });

     

});
