pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/PausableToken.sol";

contract BitcademyToken is PausableToken {
  string public constant name = "Bitcademy Gold";
  string public constant symbol = "BTMG";
  uint public constant decimals = 18;
  uint256 public constant _initial_supply = 1000000000;
  constructor(address _reserve,address _vestingAddress) public{
    require(_reserve != address(0));
    totalSupply_ = (_initial_supply*(10**decimals));
    balances[_vestingAddress]  = (totalSupply_.mul(15)).div(100);
    balances[_reserve] = (_initial_supply*(10**decimals)).sub(balances[_vestingAddress]);
    emit Transfer(this,_reserve,balances[_reserve]);
    emit Transfer(this,_vestingAddress,balances[_vestingAddress]);
  }
}
