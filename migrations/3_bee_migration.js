const Honey = artifacts.require("Honey");
const Bee = artifacts.require("Bee");
const ERC721Market = artifacts.require("ERC721Market");

module.exports = function (deployer) {
    let honey, bee;
    deployer.then(() => {
      return Honey.deployed();
    }).then((instance) => {
      honey = instance;
      return deployer.deploy(Bee);
    }).then((instance) => {
      bee = instance;
      return deployer.deploy(ERC721Market, honey.address, bee.address);
    }).then((instance) => {
      honey.grantRole("0x546bc9f4129c80b668dc5f1d6fd1d8e7a2b8ec6831c3256bdb7ac60d4f366c8c", instance.address); //keccak256("ERC20WithAccessControl/transfer")
      bee.grantRole("0x23f6052fa604a2e6d4eab83f4c6ab01d6bdf80fb1a224762896ffde93a87d4c1", instance.address); //keccak256("ERC721WithAccessControl/transfer")
    });
};