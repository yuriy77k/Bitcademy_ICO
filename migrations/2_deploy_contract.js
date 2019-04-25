//var BitcademyVesting = artifacts.require("./BitcademyVesting.sol");
//var BitcademyToken = artifacts.require("./BitcademyToken.sol");
var PreICOBitcademyGold = artifacts.require("./PreICOBitcademyGold.sol");



module.exports = function(deployer) {
   //deployer.deploy(BitcademyVesting,1556112641,216000,3888000,216000);
   //deployer.deploy(BitcademyToken,"0x7e60b69435E6408E92EA2FBf5A047495911c6012","0x7f3fcbdf736c454a7f72776e6d0568c2531fdc71");
   deployer.deploy(PreICOBitcademyGold, 4362105263000000000000, "0x90d80a61c0251db2681817e92e30d1c3d09ebf96", 1556116813, 1556199041, "0x75Cb7cc29Cc9489A85E14744391Df17Dc8cA3746", 73684210526315789000000000);
};
