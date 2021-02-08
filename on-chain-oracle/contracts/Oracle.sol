// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

import "./interfaces/OracleInterface.sol";
import "./interfaces/IDEOR.sol";
import "./library/Selection.sol";
import "./library/SafeMathDEOR.sol";
import "./library/Ownable.sol";

contract Reputation {
    using SafeMathDEOR for uint256;

    struct reputation {
        address addr;
        uint256 totalAssignedRequest;        //total number of past requests that an oracle has agreed to, both fulfilled and unfulfileed
        uint256 totalCompletedRequest;       //total number of past requests that an oracle has fulfileed
        uint256 totalAcceptedRequest;        //total number of requests that have been accepted
        uint256 totalResponseTime;           //total seconds of response time
        uint256 lastActiveTime;              //last active time of the oracle as second
        uint256 score;                       //reputation score
        uint256 penalty;                     //amount of penalty payment
        uint256 totalEarned;                 //total earned
    }

    function calculateScore(reputation memory self) internal pure returns (uint256) {
        uint256 x = (self.totalAcceptedRequest.mul(100)).div(self.totalAssignedRequest);
        uint256 b = self.totalCompletedRequest.log_2();
        if (b > 16) {
            b = 16;
        }
        uint256 res = (x.mul(b) * 9).div(1600) + 1;
        return res;
    }

    function activityValidate(reputation memory self) internal view returns (uint256) {
        uint256 ACTIVE_EXPIRY_TIME = 1 days;
        return now.sub(self.lastActiveTime) < ACTIVE_EXPIRY_TIME ? 1 : 0;
    }
}

contract Oracle is Ownable, OracleInterface, Reputation, Selection {
  using SafeMathDEOR for uint256;

  IDEOR public token;

  Request[] private requests; //  list of requests made to the contract
  uint256 private currentId = 1; // increasing request id
  uint256 public totalOracleCount = 2000; // Hardcoded oracle count
  mapping(address => reputation) private oracles;        // Reputation of oracles
  address[] private oracleAddresses;      // Saved active oracle addresses
  uint256 constant private maxResolvedCount = 1000;
  uint256[] private resolvedRequest = new uint256[](maxResolvedCount);
  uint256 cursorResolvedRequest = 0;
  uint256 constant public EXPIRY_TIME = 3 minutes;
  uint256 public requestFee = 10**10;   // request fee
  uint256 public maxSelectOracleCount = 17;

  // defines a general api request
  struct Request {
    uint256 id;                            //request id
    string requestType;                  //Request Type: "PriceFeed" or "DataQuery"
    string agreedValue;                 //value from key
    uint256 timestamp;                     //Request Timestamp
    uint256 minQuorum;                     //minimum number of responses to receive before declaring final result
    uint256 fee;                            //transaction fee
    uint256 selectedOracleCount;                //selected oracle count
    uint256 agreedPrice;                     //price from key
    uint256 paramsCount;
    mapping (uint256 => RequestParam) params;
    mapping(address => string) anwers;     //answers provided by the oracles
    mapping(address => uint256) priceAnswers;     //answers provided by the oracles
    mapping(address => uint256) quorum;    //oracles which will query the answer (1=oracle hasn't voted, 2=oracle has voted)
  }

  constructor (address tokenAddress) public {
    token = IDEOR(tokenAddress);
    requests.push(Request(0, "", "", 0, 0, 0, 0, 0, 0));
  }

  function setMaximumSelectOracleCount (uint256 value) public onlyOwner {
    maxSelectOracleCount = value;
  }

  function setRequestFee (uint256 fee) public onlyOwner {
    requestFee = fee;
  }

  function setTotalOracleCount (uint256 count) public onlyOwner {
    totalOracleCount = count;
  }

  function newOracle () public override(OracleInterface)
  {
    uint256 oracleCount = oracleAddresses.length;
    address sender = msg.sender;
    require(oracleCount < totalOracleCount, "The maximum limit of Oracles is exceeded.");
    require(oracles[sender].addr == address(0), "The oracle is already existed.");

    oracles[sender].addr = sender;
    oracles[sender].lastActiveTime = now;
    oracles[sender].score = 1;
    oracles[sender].penalty = requestFee;
    oracleAddresses.push(sender);
  }

  function removeOracleByAddress (address addr) public onlyOwner
  {
    uint256 oracleCount = oracleAddresses.length;

    for (uint256 i = 0; i < oracleCount ; i ++) {
      if (oracleAddresses[i] == addr) {
        oracleAddresses[i] = oracleAddresses[oracleCount - 1];
        delete oracleAddresses[oracleCount - 1];
        oracleAddresses.pop();

        oracles[addr].addr = address(0);      // Reset reputation of oracle to zero
        break;
      }
    }
  }

  function createRequest (
    string memory _requestType,
    RequestParam[] memory _params
  )
  public override(OracleInterface)
  {
    require(token.balanceOf(msg.sender) >= requestFee, "You haven't got enough tokens for transaction fee.");
    require(token.transfer(owner, requestFee), "DEOR Transaction Failed.");
    string memory requestType = _requestType;

    //Validate all oracles' acitivity
    uint i = 0;
    while (i < oracleAddresses.length) {
      address cursorAddress = oracleAddresses[i];
      uint256 tokenBalance = token.balanceOf(cursorAddress);

      if (tokenBalance < oracles[cursorAddress].penalty || activityValidate(oracles[cursorAddress]) == 0) {
        //Remove invalid oracle
        oracles[cursorAddress].addr = address(0);      // Reset reputation of oracle to zero
        oracles[cursorAddress].totalAssignedRequest = 0;
        oracles[cursorAddress].totalCompletedRequest = 0;
        oracles[cursorAddress].totalAcceptedRequest = 0;
        oracles[cursorAddress].totalResponseTime = 0;
        oracles[cursorAddress].lastActiveTime = now;
        oracles[cursorAddress].score = 1;
        oracles[cursorAddress].penalty = requestFee;
        oracles[cursorAddress].totalEarned = 0;

        oracleAddresses[i] = oracleAddresses[oracleAddresses.length - 1];
        delete oracleAddresses[oracleAddresses.length - 1];
        oracleAddresses.pop();

        i --;
      }
      i ++;
    }

    uint256 oracleCount = oracleAddresses.length;
    uint selectedOracleCount = oracleCount.mul(2).div(3);
    if (selectedOracleCount > maxSelectOracleCount) {
      selectedOracleCount = maxSelectOracleCount;
    }

    requests.push(Request(currentId, requestType, "", now, 0, requestFee, selectedOracleCount, 0, _params.length));
    uint256 length = requests.length;
    Request storage r = requests[length-1];

    for (i = 0 ; i < _params.length ; i ++) {
      r.params[i] = _params[i];
    }

    uint256[] memory selectedOracles = getSelectedOracles(oracleCount, selectedOracleCount);
    uint256 scoreSum = 0;
    uint256 penaltyForRequest = requestFee.div(selectedOracleCount);

    for (i = 0; i < selectedOracles.length ; i ++) {
      address selOracle = oracleAddresses[selectedOracles[i]];
      if (token.transferFrom(selOracle, owner, penaltyForRequest)) {
        r.quorum[selOracle] = 1;
        scoreSum = scoreSum.add(oracles[selOracle].score);
        oracles[selOracle].totalAssignedRequest ++;
        oracles[selOracle].penalty = penaltyForRequest;
      }
    }
    r.minQuorum = scoreSum.mul(2).div(3);          //minimum number of responses to receive before declaring final result(2/3 of total)

    // launch an event to be detected by oracle outside of blockchain
    emit NewRequest (
      currentId,
      requestType,
      _params
    );

    // increase request id
    currentId++;
  }

  //delete peding request
  function deleteRequest (uint256 _id) public override(OracleInterface) {
    delete requests[_id];
    emit DeletedRequest(_id);
  }

  function checkRetrievedValue (uint256 isDataQuery, Request storage currRequest, address oracleAddress, string memory _valueRetrieved, uint256 _priceRetrieved) 
    internal view returns (uint256)
  {
    if (isDataQuery == 1) {
      bytes memory a = bytes(currRequest.anwers[oracleAddress]);
      bytes memory b = bytes(_valueRetrieved);

      if(keccak256(a) == keccak256(b)) {
        return 1;
      }
    }
    else {
      uint256 diff = 0;
      if (currRequest.priceAnswers[oracleAddress] > _priceRetrieved) {
        diff = currRequest.priceAnswers[oracleAddress].sub(_priceRetrieved);
      }
      else {
        diff = _priceRetrieved.sub(currRequest.priceAnswers[oracleAddress]);
      }
      if (diff < _priceRetrieved.div(200)) {
        return 1;
      }
    }
    return 0;
  }

  //called by the oracle to record its answer
  function updateRequest (
    uint256 _id,
    string memory _valueRetrieved,
    uint256 _priceRetrieved
  ) public override(OracleInterface) {

    for (uint256 i = 0 ; i < maxResolvedCount ; i ++) {
      require(resolvedRequest[i] != _id, "This request is already resolved.");
    }

    Request storage currRequest = requests[_id];
    string memory vlRetrieved = _valueRetrieved;
    uint256 prRetrieved = _priceRetrieved;

    uint256 responseTime = now.sub(currRequest.timestamp);
    require(responseTime < EXPIRY_TIME, "Your answer is expired.");

    //update last active time
    oracles[address(msg.sender)].lastActiveTime = now;

    uint256 oracleCount = oracleAddresses.length;

    //check if oracle is in the list of trusted oracles
    //and if the oracle hasn't voted yet
    if(currRequest.quorum[address(msg.sender)] == 1){

      bytes memory t1 = bytes(currRequest.requestType);
      bytes memory t2 = bytes("DataQuery");
      uint256 isDataQuery = 0;
      if (keccak256(t1) == keccak256(t2)) {
        isDataQuery = 1;
      }

      oracles[address(msg.sender)].totalCompletedRequest ++;
      oracles[address(msg.sender)].totalResponseTime = oracles[address(msg.sender)].totalResponseTime.add(responseTime);

      //marking that this address has voted
      currRequest.quorum[msg.sender] = 2;

      //save the retrieved value
      if (isDataQuery == 1) {
        currRequest.anwers[address(msg.sender)] = _valueRetrieved;
      }
      else {
        currRequest.priceAnswers[address(msg.sender)] = _priceRetrieved;
      }

      uint256 currentQuorum = 0;

      //iterate through oracle list and check if enough oracles(minimum quorum)
      //have voted the same answer has the current one
      for(uint256 i = 0; i < oracleCount; i++){
        if (checkRetrievedValue(isDataQuery, currRequest, oracleAddresses[i], vlRetrieved, prRetrieved) == 1) {
          currentQuorum = currentQuorum.add(oracles[oracleAddresses[i]].score);
        }
      }

      //request Resolved
      if(currentQuorum >= currRequest.minQuorum){

        resolvedRequest[cursorResolvedRequest] = currRequest.id;
        cursorResolvedRequest = (cursorResolvedRequest + 1).mod(maxResolvedCount);
        uint256 penaltyForRequest = currRequest.fee.div(currRequest.selectedOracleCount);

        for(uint256 i = 0; i < oracleCount; i++){

          if (checkRetrievedValue(isDataQuery, currRequest, oracleAddresses[i], vlRetrieved, prRetrieved) == 1) {
            uint256 awardForRequest = currRequest.fee.div(currentQuorum).mul(oracles[oracleAddresses[i]].score);
            oracles[oracleAddresses[i]].totalAcceptedRequest ++;
            oracles[oracleAddresses[i]].totalEarned = oracles[oracleAddresses[i]].totalEarned.add(awardForRequest);
            token.transferFrom(owner, oracleAddresses[i], awardForRequest + penaltyForRequest);
          }

          // update the reputation score of the oracle
          oracles[oracleAddresses[i]].score = calculateScore(oracles[oracleAddresses[i]]);
        }

        currRequest.agreedValue = vlRetrieved;
        currRequest.agreedPrice = prRetrieved;

        RequestParam[] storage params;
        for (uint256 i = 0 ; i < currRequest.paramsCount ; i ++) {
          params.push(currRequest.params[i]);
        }

        emit UpdatedRequest (
          currRequest.id,
          currRequest.requestType,
          params,
          vlRetrieved,
          prRetrieved
        );
      }
    }
  }

  function close() public onlyOwner {
    selfdestruct(payable(owner));
  }
}
