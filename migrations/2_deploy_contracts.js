const DAO = artifacts.require("DAO");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(DAO, 2, 2, 50, accounts[9]);
};
