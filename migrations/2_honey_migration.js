const Honey = artifacts.require("Honey");
const ERC20Market = artifacts.require("ERC20Market");

module.exports = function (deployer, network, accounts) {
  let honey;
  deployer.deploy(Honey).then((instance) => {
    honey = instance;
    return deployer.deploy(ERC20Market, honey.address);
  }).then((instance) => {
    honey.grantRole("0x546bc9f4129c80b668dc5f1d6fd1d8e7a2b8ec6831c3256bdb7ac60d4f366c8c", instance.address); //keccak256("ERC20WithAccessControl/transfer")
  });
};
