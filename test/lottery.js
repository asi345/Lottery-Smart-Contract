
var Lottery = artifacts.require("Lottery");

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
        const result = lottery.calculatePrize(1,3);
        assert(result === 2.5);
    });
    it("Should reset correctly", async () =>{
        const lottery = await Lottery.deployed();
        await lottery.resetLottery();
        const result = await lottery.totalSupplies(lottery.totalSupplies.length - 1);  //doğrudur inş, güya bu getter gibiymiş
        assert(result.toNumber() === 0);  //bu çok iyi bir test değil deneme amaçlı
    });
    //bir array dönerse tüm elemanları big number olarak dönecek dolayısıyla map fonksiyonuyla onlara toNumber uygulayıp elde etmek lazımmış
    //contract blockunda uygulananlar birbrilerine bağlıdır. ilk testte bir arraye bir şey eklersen ikinci testte o eklediğin elemanı bulabilirsin.
    //assert(array === [1,2,3]); yanlış
    //assert.deepEqual(array, [1,2,3]); doğru
    //fonksiyon tuple dönüyorsa result[0], result[1] şeklinde değerleri alabilirsin
    //to test that a function reverts, use try catch



    it("Deposit Tl correctly", async () => {
        // Get initial balances of first and second account.
        const account = accounts[0];
        const lottery = await Lottery.deployed();
        const amount = 10;
        const initialBalance = await web3.eth.getBalance(account);
        const initialLotteryBalance = await web3.eth.getBalance(lottery.address);

        // Call the transfer function.
        await lottery.depositTl(amount, {from: account});   //burada account tarafından çağrıldıığını ifade edebiliyoruz.
        //{from: account, value: web3.utils.toWei('3','ether')}   defines msg.value = 3
    ;

        // Get balances after the transfer.
        const finalBalance = await web3.eth.getBalance(account);
        const finalLotteryBalance = await web3.eth.getBalance(lottery.address);

        // Test the effect of the transfer.
        assert.equal(finalBalance.toNumber(), initialBalance.toNumber() - amount, "Amount wasn't correctly deposited to the account");
        assert.equal(finalLotteryBalance.toNumber(), initialLotteryBalance.toNumber() + amount, "Amount wasn't correctly deposited to the contract");

        //balances taki elemanlara nasıl ulaşırız bakmak lazım
       
    });
});



