//const HDWalletProvider = require("truffle-hdwallet-provider-privkey");
//const privKey = "80248670d6309e74d63ad7afa9cef82a6fadcbcccbdd2a25eb69a08e1053b5c1";
const mnemonic = "come hover maple exhaust proud invite sweet elegant seven pair stock toy";
const HDWalletProvider = require("truffle-hdwallet-provider");

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!

    networks: {
      ropsten: {
        provider: () => { return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/PGeaCCgYpthSugPncips")},
        network_id: '3'
      },
      rinkeby: {
        "gas": 7000000,
        "gasPrice": 100000000000,
         provider: () => { return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/PGeaCCgYpthSugPncips")},
         network_id: '4'
      },
      development: {
          host: "127.0.0.1",
          port: 8545,
          network_id: "*" // Match any network id
      }
  }
};
