//var BitcademyVesting = artifacts.require("./BitcademyVesting.sol");
//var BitcademyToken = artifacts.require("./BitcademyToken.sol");
var PreICOBitAcademyGold = artifacts.require("./PreICOBitcademyGold.sol");



module.exports = function(deployer) {
    //deployer.deploy(BitcademyVesting,1542830332,216000,3888000,216000);
    //deployer.deploy(BitcademyToken,"0x75Cb7cc29Cc9489A85E14744391Df17Dc8cA3746","0xa27cf7efe29b2dfd8a4f30c58126068523e16f21");
    deployer.deploy(PreICOBitAcademyGold, 3076, "0x270650c8211ca8fcae10e8e6ada84f501a6b1112", 1543748113, 1545398291, "0x75Cb7cc29Cc9489A85E14744391Df17Dc8cA3746", 105263158000000000000000000);
};
