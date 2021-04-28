const UpgradableHive = artifacts.require("UpgradableHive");
const Honey = artifacts.require("Honey");
const Bee = artifacts.require("Bee");

module.exports = function (deployer) {
  let hive, honey, bee;
  deployer.then(() => {
    return Honey.deployed();
  }).then((instance) => {
    honey = instance;
    return Bee.deployed();
  }).then((instance) => {
    bee = instance;
    return deployer.deploy(UpgradableHive, bee.address, honey.address,1,60*60*24,1000);
  }).then((instance) => {
    hive = instance;
    honey.grantRole("0x6a00e5d101d1200e4e1aefd969d7e16bb0f9791d2b2a440afb0e855965f4a1b1", hive.address); //keccak256("ERC20WithAccessControl/mint")
    honey.grantRole("0x761344200b283ac7a811904d6d5b56b312dbd2d942fa9e0191c3ec20188089f7", hive.address); //keccak256("ERC20WithAccessControl/burn")
    honey.grantRole("0x546bc9f4129c80b668dc5f1d6fd1d8e7a2b8ec6831c3256bdb7ac60d4f366c8c", hive.address); //keccak256("ERC20WithAccessControl/transfer")
    bee.grantRole("0x23f6052fa604a2e6d4eab83f4c6ab01d6bdf80fb1a224762896ffde93a87d4c1", hive.address); //keccak256("ERC721WithAccessControl/transfer")
    return bee.grantRole("0x06fc0947e78f6ad798992339dea77d6a12ab077d27fe61501300d0f694b61b96", hive.address); //keccak256("ERC721WithAccessControl/mint")
    //hive.setup("Beektor");
    // hive.forceEnlarge(["Bumblebee","Frebee Mercury","Obeewan Kenobee", "Alibabee", "Bambee", "Beethoven"]);
  }).then(() => {
    hive.setup("Beektor");
  });
};
