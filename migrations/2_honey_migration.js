const Honey = artifacts.require("Honey");

module.exports = function (deployer, network, accounts) {
  deployer.deploy(Honey).then((honey) => {
    accounts.forEach(account => {
      honey.mint(account, 100);
    });
  });
};
