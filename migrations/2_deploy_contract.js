var BitcademyVesting = artifacts.require("./BitcademyVesting.sol");
var BitcademyToken = artifacts.require("./BitcademyToken.sol");
var PreICOBitAcademyGold = artifacts.require("./PreICOBitcademyGold.sol");




module.exports = function(deployer) {
    //deployer.deploy(BitcademyVesting,1533648600,600,10800);
    deployer.deploy(BitcademyToken,"0x7e60b69435E6408E92EA2FBf5A047495911c6012","0x9c3d28f2fdc80933d0c09edcf415aa48ed91d4db",1000000000);
  //deployer.deploy(PreICOBitAcademyGold,73079733835916,"0x37f90f9BE74C6Af83e2eFA6A918ca5D38eB655e4","0x6454835367dfe5bcb3787fdb968ac0bdc3ece1d9",1529487347,1529573747, "0x37f90f9BE74C6Af83e2eFA6A918ca5D38eB655e4");
};
