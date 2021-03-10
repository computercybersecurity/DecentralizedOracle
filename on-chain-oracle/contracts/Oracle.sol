// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

import "./interfaces/OracleInterface.sol";
import "./interfaces/IDEOR.sol";
import "./interfaces/IOracles.sol";
import "./interfaces/IPriceFeed.sol";
import "./interfaces/IDataQuery.sol";
import "./library/Selection.sol";
import "./library/SafeMathDEOR.sol";
import "./library/Ownable.sol";

contract Oracle is Ownable, OracleInterface, Selection {
  using SafeMathDEOR for uint256;

  IDEOR private token;
  IOracles private oracles;

  Request[] private requests; //  list of requests made to the contract
  uint256 public currentId = 1; // increasing request id
  uint private totalOracleCount = 2000; // Hardcoded oracle count
  uint256 constant private EXPIRY_TIME = 3 minutes;
  uint256 public requestFee = 100 * (10**10);   // request fee
  uint private maxSelectOracleCount = 17;

  constructor (address tokenAddress, address oracleAddress) public {
    token = IDEOR(tokenAddress);
    oracles = IOracles(oracleAddress);
    requests.push(Request(0, "", 0, address(0x0), "", 0, 0, 0, 0, 0));
  }

  function setRequestFee (uint256 fee) public onlyOwner {
    requestFee = fee;
  }

  function newOracle (string memory name) public override(OracleInterface)
  {
    oracles.newOracle(name, msg.sender, requestFee);
    emit NewOracle(msg.sender);
  }

  function createRequest (
    string memory queries,
    uint8 qtype,
    address contractAddr
  )
  public override(OracleInterface)
  {
    require(token.balanceOf(msg.sender) >= requestFee, "Invalid fee.");
    require(token.transferFrom(msg.sender, owner, requestFee), "DEOR transfer Failed.");

    uint i = 0;
    uint len = oracles.getOracleCount();
    uint selectedOracleCount = (len * 2 + 2) / 3;
    if (selectedOracleCount > maxSelectOracleCount) {
      selectedOracleCount = maxSelectOracleCount;
    }

    requests.push(Request(currentId, queries, qtype, contractAddr, "", 0, block.timestamp, 0, requestFee, selectedOracleCount));
    uint256 length = requests.length;
    Request storage r = requests[length-1];

    uint256[] memory orderingOracles = getSelectedOracles(len);
    uint256 penaltyForRequest = requestFee.div(selectedOracleCount);
    uint count = 0;

    for (i = 0; i < len && count < selectedOracleCount ; i ++) {
      address selOracle = oracles.getOracleByIndex(orderingOracles[i]);
      //Validate oracle's acitivity
      if (token.transferFrom(selOracle, owner, penaltyForRequest) && now < oracles.getOracleLastActiveTime(selOracle) + 1 days) {
        r.quorum[selOracle] = 1;
        count ++;
        oracles.increaseOracleAssigned(selOracle, penaltyForRequest);
      }
    }
    r.minQuorum = (count * 2 + 2) / 3;          //minimum number of responses to receive before declaring final result(2/3 of total)

    // launch an event to be detected by oracle outside of blockchain
    emit NewRequest (
      currentId,
      queries,
      qtype
    );

    // increase request id
    currentId ++;
  }

  function checkRetrievedValue (Request storage currRequest, address oracleAddress, string memory _valueRetrieved, int256 _priceRetrieved) 
    internal view returns (bool)
  {
    if (currRequest.qtype == 0) {
      bytes memory a = bytes(currRequest.answers[oracleAddress]);
      bytes memory b = bytes(_valueRetrieved);

      if(keccak256(a) == keccak256(b)) {
        return true;
      }
    }
    else {
      int256 diff = 0;
      if (currRequest.priceAnswers[oracleAddress] > _priceRetrieved) {
        diff = currRequest.priceAnswers[oracleAddress] - _priceRetrieved;
      }
      else {
        diff = _priceRetrieved - currRequest.priceAnswers[oracleAddress];
      }
      if (diff < _priceRetrieved / 200) {
        return true;
      }
    }
    return false;
  }

  //called by the oracle to record its answer
  function updateRequest (
    uint256 _id,
    string memory _valueRetrieved,
    int256 _priceRetrieved
  ) public override(OracleInterface) {

    Request storage currRequest = requests[_id];

    uint256 responseTime = block.timestamp.sub(currRequest.timestamp);
    require(responseTime < EXPIRY_TIME, "Your answer is expired.");

    //update last active time
    oracles.updateOracleLastActiveTime(msg.sender);

    //check if oracle is in the list of trusted oracles
    //and if the oracle hasn't voted yet
    if(currRequest.quorum[msg.sender] == 1){

      oracles.increaseOracleCompleted(msg.sender, responseTime);

      //marking that this address has voted
      currRequest.quorum[msg.sender] = 2;

      //save the retrieved value
      if (currRequest.qtype == 0) {
        currRequest.answers[msg.sender] = _valueRetrieved;
      }
      else {
        currRequest.priceAnswers[msg.sender] = _priceRetrieved;
      }

      uint i = 0;
      uint256 currentQuorum = 0;
      uint len = oracles.getOracleCount();
      uint8[] memory flag = new uint8[](len);

      //iterate through oracle list and check if enough oracles(minimum quorum)
      //have voted the same answer has the current one
      for (i = 0 ; i < len ; i ++) {
        if (checkRetrievedValue(currRequest, oracles.getOracleByIndex(i), _valueRetrieved, _priceRetrieved)) {
          currentQuorum ++;
          flag[i] = 1;
        }
      }

      //request Resolved
      if(currentQuorum >= currRequest.minQuorum) {

        uint256 penaltyForRequest = currRequest.fee.div(currRequest.selectedOracleCount);

        for (i = 0 ; i < len ; i ++) {

          if (flag[i] == 1) {
            uint256 awardForRequest = currRequest.fee.div(currentQuorum);
            address addr = oracles.getOracleByIndex(i);
            oracles.increaseOracleAccepted(addr, awardForRequest);
            token.transferFrom(owner, addr, awardForRequest + penaltyForRequest);
          }
        }

        currRequest.agreedValue = _valueRetrieved;

        if (currRequest.qtype == 0) {     // data aggregator
          IDataQuery _feed = IDataQuery(currRequest.contractAddr);
          _feed.addRequestAnswer(_valueRetrieved);
        }
        else if (currRequest.qtype == 1) {     // price aggregator
          if (currRequest.contractAddr != address(0x0)) {
            IPriceFeed _feed = IPriceFeed(currRequest.contractAddr);
            _feed.addRequestAnswer(_priceRetrieved);
          }
        }

        emit UpdatedRequest (
          currRequest.id,
          currRequest.queries,
          currRequest.qtype,
          _valueRetrieved,
          _priceRetrieved
        );
      }
    }
  }
}
