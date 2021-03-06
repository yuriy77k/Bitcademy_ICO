pragma solidity ^0.4.23;

import "./BitcademyToken.sol";
import "./RefundVault.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
/**
 * @title PreICOBitcademyGold
 * @dev PreICOBitcademyGold is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropiate to concatenate
 * behavior.
 */
contract PreICOBitcademyGold is Ownable{
  using SafeMath for uint256;

  // The token being sold
  BitcademyToken public token;

  // Address where funds are collected
  //address public wallet;
   //address public _multi_sig_wallet = 0xc5384F3d5602eC5F52e50F28e650685E9c5F3016;

    //custom release date
   uint256 public release_date = 1556582400;
  // No of Tokens per Ether
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;


  //amount of tokens to be sold for Private Sale preICO
  uint256 public supply_cap = 150000000*(10**18);
  // maximum token selleable without bonuses
  uint256 public minimumTokens = 93750000*(10**18);


  address[] public investors;
  address[] public blacklist;



  mapping(address => bool) public whitelist;
  mapping(address => bool) public blacklisted;
  mapping (address => uint256) public tokenToClaim;
// amount invested by the investor
   mapping (address => uint256) public investedAmount;

  uint256 public openingTime;
  uint256 public closingTime;

  // Remaining tokens which are yet to be sold
  uint256 public remainingTokens;

  // Tokens sold excluding bonus
  uint256 public tokenSoldExcludeBonus;

  // minimum amount of funds to be raised in weis
  uint256 public goal;

  // refund vault used to hold funds while crowdsale is running
  RefundVault public vault;
 // refund amount for the blacklisted users
  uint256 public refundBlackListedAmount;
  /**
   * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
   */
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  /**
   * @dev Reverts if the beneficiary is not blacklisted.
   */
  modifier onlyBlacklisted(address _beneficiary) {
    require(blacklisted[_beneficiary]);
    _;
  }


  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract's finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

  /**
   * @dev Investors can claim refunds here if crowdsale is unsuccessful
   */
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

  /**
   * @dev  Investors can claim refunds here if they are  blacklisted
   */
  function blacklistClaimRefund() onlyBlacklisted(msg.sender) public  {
    require(isFinalized);
    require(tokenToClaim[msg.sender] > 0);
    vault.refund(msg.sender);
    tokenToClaim[msg.sender] = 0;
  }

  /**
   * @dev Checks whether funding goal was reached.
   * @return Whether funding goal was reached
   */
  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }



  /**
   * @dev vault finalization task, called when owner calls finalize()
   */
  function finalization() internal {
    if (goalReached()) {
      if (refundBlackListedAmount > 0){
        for (uint i = 0; i < blacklist.length; i++) {
          address blacklistedInvestor = blacklist[i];
          require(tokenToClaim[blacklistedInvestor] > 0);
          if (vault.deposited(blacklistedInvestor) != 0) {
           vault.refund(blacklistedInvestor);
           tokenToClaim[blacklistedInvestor] = 0;
         }
        }
      }
      vault.close();
    } else {
      vault.enableRefunds();
    }
  }

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * @param _rate No of tokens per ether
   * @param _multi_sig_wallet Address where collected funds will be forwarded to
   * @param _goal the  token soft cap
   */
  constructor(uint256 _rate , BitcademyToken _token, uint256 _openingTime, uint256 _closingTime, address _multi_sig_wallet, uint256 _goal) public {
    require(_rate > 0);
    require(_multi_sig_wallet != address(0));
    require(_token != address(0));
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);
    require(_goal > 0);

    vault = new RefundVault(_multi_sig_wallet);
    goal = _goal;
    rate = _rate;
    token = _token;
    openingTime = _openingTime;
    closingTime = _closingTime;
}
  // -----------------------------------------
  // PreICOBitcademyGold external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public isWhitelisted(_beneficiary) payable {
    uint256 mimimumInvestment = 10**18;
    uint256 weiAmount = msg.value;
    if (investedAmount[_beneficiary] == 0){
      require(weiAmount > mimimumInvestment);
    }

    uint256 refundWeiAmt = 0;
    uint256 tokens = 0;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be delivered
     (tokens, refundWeiAmt) = _getTokenAmount(weiAmount);

    /* If the remaining tokens are less than tokens calculated above
     * proceed with purchase of remaining tokens and refund the remaining ethers
     * to the caller
     */
    if(refundWeiAmt > 0) {
      msg.sender.transfer(refundWeiAmt);
      weiAmount = weiAmount.sub(refundWeiAmt);
    }

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);
    _forwardFunds(weiAmount);
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
  function addToWhitelist(address _beneficiary) external onlyOwner {
    require(!isFinalized);
    whitelist[_beneficiary] = true;
  }

  /**
   * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    require(!isFinalized);
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    require(!isFinalized);
    whitelist[_beneficiary] = false;
    if (tokenToClaim[_beneficiary] > 0){
      refundBlackListedAmount = refundBlackListedAmount.add(tokenToClaim[_beneficiary]);
      blacklist.push(_beneficiary);
    }
    blacklisted[_beneficiary] = true;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > closingTime;
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    pure internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount > 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    view internal
  {
    // optional override
      require(investedAmount[_beneficiary] > 0 && _weiAmount > 0);
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal isWhitelisted(msg.sender)
  {
    token.transfer(_beneficiary, _tokenAmount);

  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
    isWhitelisted(_beneficiary)
    onlyWhileOpen
  {
    //_deliverTokens(_beneficiary, _tokenAmount);
    if (tokenToClaim[_beneficiary] == 0){
    tokenToClaim[_beneficiary] = _tokenAmount;
    }
    else{
      tokenToClaim[_beneficiary] = tokenToClaim[_beneficiary].add(_tokenAmount);
    }
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    pure internal
  {
    // optional override
    require(_beneficiary != address(0));
    require(_weiAmount > 0);
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Token price in weis
   */
  function _getTokenAmount(uint256 _weiAmount)
    isWhitelisted(msg.sender) internal  returns (uint256, uint256)
  {
    remainingTokens =  token.balanceOf(this);
    uint256 noOfTokens = 0;
    uint256 tokensInCondition = 0;
    uint256 weiAmount  = _weiAmount;
    uint256 currentRate = 0;
    uint256 tokensMinusBonus = 0;
    require(tokenSoldExcludeBonus < 93750000*(10**18));
      currentRate = rate;
      tokensMinusBonus = currentRate*(10**18);
      tokenSoldExcludeBonus = tokenSoldExcludeBonus.add(tokensMinusBonus);
      currentRate = currentRate.mul(16);
      currentRate = currentRate.div(10);
      tokensInCondition = currentRate * (10**18) * (_weiAmount/10**18);
      weiAmount = weiAmount.sub(tokensInCondition.mul(currentRate));
      noOfTokens = noOfTokens.add(tokensInCondition);
      remainingTokens = remainingTokens.sub(tokensInCondition);

    return (noOfTokens, weiAmount);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds(uint256 _value) internal isWhitelisted(msg.sender) {
    vault.deposit.value(_value)(msg.sender);
    if (investedAmount[msg.sender] == 0){
      investedAmount[msg.sender] = _value;
      investors.push(msg.sender);
    }
    else {
      investedAmount[msg.sender] = investedAmount[msg.sender].add(_value);
      investors.push(msg.sender);
    }
  }
   /**
   * @dev Set the exchange rate of the token
   */
  function setRate(uint256 _rate) public onlyOwner{
    require(_rate > 0);
    rate = _rate;
  }

   /**
   * @dev calculate the number of investors in crowdsale
   */

  function investorsCount() public constant returns (uint) {
    return investors.length;
  }

    /**
   * @dev Allow investors to withdraw their tokens after the mainsale is done
   */

  function withdrawAfterMainSale() isWhitelisted(msg.sender) public {
    require(goalReached());
    require(release_date < now);
    require(isFinalized);
    require(tokenToClaim[msg.sender] >= 0);
      if (tokenToClaim[msg.sender] > 0) {
         _deliverTokens(msg.sender, tokenToClaim[msg.sender]);
         tokenToClaim[msg.sender] = 0;
      }
  }

    /**
   * @dev Update the release date of purchased tokens
   */

  function updateReleaseDate(uint256 _new_release_date) onlyOwner public{
    require(_new_release_date > now &&  _new_release_date != release_date);
     release_date = _new_release_date;
    }

      /**
   * @dev Update the close date of crowdsale
   */

    function adjustCloseDate(uint256 _new_close_date) onlyOwner public{
    require(!isFinalized);
    require(_new_close_date > now &&  _new_close_date > closingTime );
     closingTime = _new_close_date;
    }

    /**
 * @dev get goal amount
 */
    function getGoal() onlyOwner public view returns (uint256){
    return goal;
    }
}
