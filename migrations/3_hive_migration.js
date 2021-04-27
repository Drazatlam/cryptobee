const Hive = artifacts.require("Hive");
const Honey = artifacts.require("Honey");

module.exports = function (deployer) {
  let hive, honey;
  deployer.then(() => {
    return Honey.deployed();
  }).then((instance) => {
    honey = instance;
    return deployer.deploy(Hive, honey.address,["Beektor","Bumblebee","Frebee Mercury","Obeewan Kenobee", "Alibabee", "Bambee", "Beethoven"],1,1);
  }).then((instance) => {
    hive = instance;
    honey.transferOwnership(hive.address); 
  });
};
