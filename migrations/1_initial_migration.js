const Migrations = artifacts.require("Migrations");
const TL = artifacts.require("TL");
const Ticket = artifacts.require("Ticket");
const Lottery = artifacts.require("Lottery");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
  //deployer.deploy(TL);
  //deployer.deploy(Ticket);
  deployer.deploy(Lottery);
};
