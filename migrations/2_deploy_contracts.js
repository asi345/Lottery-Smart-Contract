const Lottery = artifacts.require("Lottery");

module.exports = function (deployer) {
  //deployer.deploy(Lottery,{gas: 10000000000});
  deployer.deploy(Lottery);
};
