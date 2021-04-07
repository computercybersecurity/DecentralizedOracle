// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

import "./interfaces/IPriceOracle.sol";
import "./interfaces/IDEOR.sol";
import "./interfaces/IOracles.sol";
import "./interfaces/IPriceFeed.sol";
import "./interfaces/IDataQuery.sol";
import "./library/Selection.sol";
import "./library/SafeMathDEOR.sol";
import "./library/Ownable.sol";

contract PriceOracle is Ownable, IPriceOracle, Selection {
  using SafeMathDEOR for uint256;

  IDEOR private token;
  IOracles private oracles;

  Request[] private requests; //  list of requests made to the contract
  uint256 public currentId = 1; // increasing request id
  uint256 constant private EXPIRY_TIME = 3 minutes;
  uint256 public requestFee = 100 * (10**10);   // request fee

  constructor (address tokenAddress, address oracleAddress) public {
    token = IDEOR(tokenAddress);
    oracles = IOracles(oracleAddress);
    requests.push(Request(0, 0, 0, 0, 0, false, address(0x0), ""));
  }

  function setRequestFee (uint256 fee) public onlyOwner {
    requestFee = fee;
  }

  function createRequest (
    string memory queries,
    address contractAddr
  )
  public override(IPriceOracle)
  {
    token.transferFrom(msg.sender, address(this), requestFee);

    uint256 len = oracles.getOracleCount();
    uint256 selectedOracleCount = len * 2 / 3 + 1;

    requests.push(Request(currentId, block.timestamp, 0, selectedOracleCount, 0, false, contractAddr, queries));
    Request storage r = requests[requests.length - 1];

    uint256[] memory orderingOracles = getSelectedOracles(len);
    uint256 penaltyForRequest = requestFee.div(selectedOracleCount);
    uint256 count = 0;

    for (uint256 i = 0; i < len && count < selectedOracleCount ; i ++) {
      address selOracle = oracles.getOracleByIndex(orderingOracles[i]);
      //Validate oracle's acitivity
      if (now < oracles.getOracleLastActiveTime(selOracle) + 1 days && token.balanceOf(selOracle) >= penaltyForRequest) {
        token.transferFrom(selOracle, address(this), penaltyForRequest);
        r.quorum[selOracle] = 1;
        count ++;
        oracles.increaseOracleAssigned(selOracle);
      }
    }
    r.minQuorum = (count * 2 + 2) / 3;          //minimum number of responses to receive before declaring final result(2/3 of total)

    // launch an event to be detected by oracle outside of blockchain
    emit NewRequest (
      currentId,
      queries,
      contractAddr
    );

    // increase request id
    currentId ++;
  }

  function checkRetrievedValue (int256 _priceAnswer, int256 _priceRetrieved) 
    internal pure returns (bool)
  {
    int256 diff = 0;
    if (_priceAnswer > _priceRetrieved) {
      diff = _priceAnswer - _priceRetrieved;
    }
    else {
      diff = _priceRetrieved - _priceAnswer;
    }
    if (diff < _priceRetrieved / 200) {
      return true;
    }
    return false;
  }

  //called by the oracle to record its answer
  function updateRequest (
    uint256 _id,
    int256 _priceRetrieved
  ) public override(IPriceOracle) {

    Request storage currRequest = requests[_id];

    uint256 responseTime = block.timestamp.sub(currRequest.timestamp);
    require(responseTime < EXPIRY_TIME, "Your answer is expired.");

    //update last active time
    oracles.updateOracleLastActiveTime(msg.sender);

    //check if oracle is in the list of trusted oracles
    //and if the oracle hasn't voted yet
    if(currRequest.quorum[msg.sender] == 1) {

      oracles.increaseOracleCompleted(msg.sender, responseTime);

      //marking that this address has voted
      currRequest.quorum[msg.sender] = 2;

      //save the retrieved value
      currRequest.priceAnswers[msg.sender] = _priceRetrieved;

      uint256 penaltyForRequest = requestFee.div(currRequest.selectedOracleCount);

      if (currRequest.isFinished == true) {
        if (checkRetrievedValue(currRequest.agreedPrice, _priceRetrieved)) {
          oracles.increaseOracleAccepted(msg.sender, penaltyForRequest);
          token.transfer(msg.sender, penaltyForRequest + penaltyForRequest);
        }
      }
      else {
        uint256 i = 0;
        uint256 currentQuorum = 0;
        uint256 len = oracles.getOracleCount();
        uint8[] memory flag = new uint8[](len);

        //iterate through oracle list and check if enough oracles(minimum quorum)
        //have voted the same answer has the current one
        for (i = 0 ; i < len ; i ++) {
          if (checkRetrievedValue(currRequest.priceAnswers[oracles.getOracleByIndex(i)], _priceRetrieved)) {
            currentQuorum ++;
            flag[i] = 1;
          }
        }

        //request Resolved
        if(currentQuorum >= currRequest.minQuorum) {
          for (i = 0 ; i < len ; i ++) {
            if (flag[i] == 1) {
              address addr = oracles.getOracleByIndex(i);
              oracles.increaseOracleAccepted(addr, penaltyForRequest);
              token.transfer(addr, penaltyForRequest + penaltyForRequest);
            }
          }

          currRequest.agreedPrice = _priceRetrieved;
          currRequest.isFinished = true;

          emit UpdatedPrice (
            currRequest.id,
            _priceRetrieved,
            currRequest.contractAddr
          );
        }
      }
    }
  }
}
