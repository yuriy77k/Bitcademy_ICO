//var BitcademyVesting = artifacts.require("./BitcademyVesting.sol");
//var BitcademyToken = artifacts.require("./BitcademyToken.sol");
var PreICOBitcademyGold = artifacts.require("./PreICOBitcademyGold.sol");



module.exports = function(deployer) {
   // deployer.deploy(BitcademyVesting,1545730208,216000,3888000,216000);
   // deployer.deploy(BitcademyToken,"0x7e60b69435E6408E92EA2FBf5A047495911c6012","0x7010a2f420298fa15229b1d6d0b5ef0df16b1f89");
   deployer.deploy(PreICOBitcademyGold, 2688947368421000000000, "0x90d80a61c0251db2681817e92e30d1c3d09ebf96", 1545345910, 1546194300, "0x75Cb7cc29Cc9489A85E14744391Df17Dc8cA3746", 105263158000000000000000000);
};
