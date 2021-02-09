// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

import "./interfaces/OracleInterface.sol";
import "./interfaces/IDEOR.sol";
import "./library/Selection.sol";
import "./library/SafeMathDEOR.sol";
import "./library/Ownable.sol";

contract Oracle is Ownable, OracleInterface, Selection {
  using SafeMathDEOR for uint256;

  IDEOR private token;

  Request[] private requests; //  list of requests made to the contract
  uint256 private currentId = 1; // increasing request id
  uint private totalOracleCount = 2000; // Hardcoded oracle count
  mapping(address => reputation) private oracles;        // Reputation of oracles
  address[] private oracleAddresses;      // Saved active oracle addresses
  uint constant private EXPIRY_TIME = 3 minutes;
  uint256 public requestFee = 10**10;   // request fee
  uint private maxSelectOracleCount = 17;

  constructor (address tokenAddress) public {
    token = IDEOR(tokenAddress);
    requests.push(Request(0, "", "", "", 0, 0, 0, 0));
  }

  function setRequestFee (uint256 fee) public onlyOwner {
    requestFee = fee;
  }

  function newOracle () public override(OracleInterface)
  {
    require(oracleAddresses.length < totalOracleCount, "oracle overflow");
    require(oracles[msg.sender].addr == address(0), "already exists");

    oracles[msg.sender].addr = msg.sender;
    oracles[msg.sender].lastActiveTime = now;
    oracles[msg.sender].penalty = requestFee;
    oracleAddresses.push(msg.sender);
  }

  function getOracleReputations () public view returns (reputation[] memory) {
    uint oracleCount = oracleAddresses.length;
    reputation[] memory res = new reputation[](oracleCount);

    for (uint i = 0; i < oracleCount ; i ++) {
      res[i].addr = oracles[oracleAddresses[i]].addr;
      res[i].totalAssignedRequest = oracles[oracleAddresses[i]].totalAssignedRequest;
      res[i].totalCompletedRequest = oracles[oracleAddresses[i]].totalCompletedRequest;
      res[i].totalAcceptedRequest = oracles[oracleAddresses[i]].totalAcceptedRequest;
      res[i].totalResponseTime = oracles[oracleAddresses[i]].totalResponseTime;
      res[i].lastActiveTime = oracles[oracleAddresses[i]].lastActiveTime;
      res[i].penalty = oracles[oracleAddresses[i]].penalty;
      res[i].totalEarned = oracles[oracleAddresses[i]].totalEarned;
    }

    return res;
  }

  function removeOracleByAddress (address addr) public onlyOwner
  {
    for (uint i = 0; i < oracleAddresses.length ; i ++) {
      if (oracleAddresses[i] == addr) {
        oracleAddresses[i] = oracleAddresses[oracleAddresses.length - 1];
        delete oracleAddresses[oracleAddresses.length - 1];
        oracleAddresses.pop();

        oracles[addr].addr = address(0);      // Reset reputation of oracle to zero
        break;
      }
    }
  }

  function createRequest (
    string memory urlToQuery,
    string memory attributeToFetch
  )
  public override(OracleInterface)
  {
    require(token.balanceOf(msg.sender) >= requestFee, "Invalid fee.");
    require(token.transfer(owner, requestFee), "DEOR transfer Failed.");

    uint i = 0;
    uint selectedOracleCount = oracleAddresses.length * 2 / 3;
    if (selectedOracleCount > maxSelectOracleCount) {
      selectedOracleCount = maxSelectOracleCount;
    }

    requests.push(Request(currentId, urlToQuery, attributeToFetch, "", now, 0, requestFee, selectedOracleCount));
    uint256 length = requests.length;
    Request storage r = requests[length-1];

    uint256[] memory selectedOracles = getSelectedOracles(oracleAddresses.length, selectedOracleCount);
    uint256 penaltyForRequest = requestFee.div(selectedOracleCount);
    uint count = 0;

    for (i = 0; i < selectedOracles.length ; i ++) {
      address selOracle = oracleAddresses[selectedOracles[i]];
      //Validate oracle's acitivity
      if (token.transferFrom(selOracle, owner, penaltyForRequest) && now.sub(oracles[selOracle].lastActiveTime) < 1 days) {
        r.quorum[selOracle] = 1;
        count ++;
        oracles[selOracle].totalAssignedRequest ++;
        oracles[selOracle].penalty = penaltyForRequest;
      }
    }
    r.minQuorum = count * 2 / 3;          //minimum number of responses to receive before declaring final result(2/3 of total)

    // launch an event to be detected by oracle outside of blockchain
    emit NewRequest (
      currentId,
      urlToQuery,
      attributeToFetch
    );

    // increase request id
    currentId++;
  }

  //called by the oracle to record its answer
  function updateRequest (
    uint256 _id,
    string memory _valueRetrieved
  ) public override(OracleInterface) {

    Request storage currRequest = requests[_id];

    uint responseTime = now.sub(currRequest.timestamp);
    require(responseTime < EXPIRY_TIME, "Your answer is expired.");

    //update last active time
    oracles[msg.sender].lastActiveTime = now;

    //check if oracle is in the list of trusted oracles
    //and if the oracle hasn't voted yet
    if(currRequest.quorum[msg.sender] == 1){

      oracles[msg.sender].totalCompletedRequest ++;
      oracles[msg.sender].totalResponseTime = oracles[msg.sender].totalResponseTime + responseTime;

      //marking that this address has voted
      currRequest.quorum[msg.sender] = 2;

      //save the retrieved value
      currRequest.anwers[msg.sender] = _valueRetrieved;

      uint i = 0;
      uint256 currentQuorum = 0;
      uint8[] memory flag = new uint8[](oracleAddresses.length);

      //iterate through oracle list and check if enough oracles(minimum quorum)
      //have voted the same answer has the current one
      for(i = 0; i < oracleAddresses.length; i++){
        bytes memory a = bytes(currRequest.anwers[oracleAddresses[i]]);
        bytes memory b = bytes(_valueRetrieved);

        if(keccak256(a) == keccak256(b)) {
          currentQuorum ++;
          flag[i] = 1;
        }
      }

      //request Resolved
      if(currentQuorum >= currRequest.minQuorum){

        uint256 penaltyForRequest = currRequest.fee.div(currRequest.selectedOracleCount);

        for(i = 0; i < oracleAddresses.length; i++){

          if (flag[i] == 1) {
            uint256 awardForRequest = currRequest.fee.div(currentQuorum);
            oracles[oracleAddresses[i]].totalAcceptedRequest ++;
            oracles[oracleAddresses[i]].totalEarned = oracles[oracleAddresses[i]].totalEarned + awardForRequest;
            token.transferFrom(owner, oracleAddresses[i], awardForRequest + penaltyForRequest);
          }
        }

        currRequest.agreedValue = _valueRetrieved;

        emit UpdatedRequest (
          currRequest.id,
          currRequest.urlToQuery,
          currRequest.attributeToFetch,
          _valueRetrieved
        );
      }
    }
  }
}
