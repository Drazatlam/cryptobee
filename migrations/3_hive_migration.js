const UpgradableHive = artifacts.require("UpgradableHive");
const Honey = artifacts.require("Honey");
const ERC721Market = artifacts.require("ERC721Market");

module.exports = function (deployer) {
  let hive, honey;
  deployer.then(() => {
    return Honey.deployed();
  }).then((instance) => {
    honey = instance;
    return deployer.deploy(UpgradableHive,1000);
  }).then((instance) => {
    hive = instance;
    hive.setup(honey.address,["Beektor"],0,1,60*60*24);
    hive.forceEnlarge(["Bumblebee","Frebee Mercury","Obeewan Kenobee", "Alibabee", "Bambee", "Beethoven"]);
    honey.grantRole("0x6a00e5d101d1200e4e1aefd969d7e16bb0f9791d2b2a440afb0e855965f4a1b1", hive.address); //keccak256("ERC20WithAccessControl/mint")
    honey.grantRole("0x761344200b283ac7a811904d6d5b56b312dbd2d942fa9e0191c3ec20188089f7", hive.address); //keccak256("ERC20WithAccessControl/burn")
    honey.grantRole("0x546bc9f4129c80b668dc5f1d6fd1d8e7a2b8ec6831c3256bdb7ac60d4f366c8c", hive.address); //keccak256("ERC20WithAccessControl/transfer")
    return deployer.deploy(ERC721Market, honey.address, hive.address);
  }).then((instance) => {
    honey.grantRole("0x546bc9f4129c80b668dc5f1d6fd1d8e7a2b8ec6831c3256bdb7ac60d4f366c8c", instance.address); //keccak256("ERC20WithAccessControl/transfer")
    hive.grantRole("0x23f6052fa604a2e6d4eab83f4c6ab01d6bdf80fb1a224762896ffde93a87d4c1", instance.address); //keccak256("ERC721WithAccessControl/transfer")
  });
};
