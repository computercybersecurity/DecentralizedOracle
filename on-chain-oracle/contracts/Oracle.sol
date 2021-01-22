pragma solidity >=0.4.21 <0.6.0;

import "./library/Selection.sol";
import "./library/Reputation.sol";
import "./library/SafeMath.sol";

contract Oracle {
  using SafeMath for uint256;

  Request[] requests; //  list of requests made to the contract
  uint256 currentId = 1; // increasing request id
  uint256 totalOracleCount = 2000; // Hardcoded oracle count
  mapping(address => Reputation.reputation) oracles;        // Reputation of oracles
  address[] oracleAddresses;      // Saved active oracle addresses
  address administrator = address(0xafec828FF5BD140FfB42a251AD7435155E7b29bd);
  uint256 maxResolvedCount = 1000;
  uint256[] resolvedRequest = new uint256[](maxResolvedCount);
  uint256 cursorResolvedRequest = 0;
  uint256 constant public EXPIRY_TIME = 3 minutes;

  // defines a general api request
  struct Request {
    uint256 id;                            //request id
    string urlToQuery;                  //API url
    string attributeToFetch;            //json attribute (key) to retrieve in the response
    string agreedValue;                 //value from key
    uint256 timestamp;                     //Request Timestamp
    uint256 minQuorum;                     //minimum number of responses to receive before declaring final result
    mapping(address => string) anwers;     //answers provided by the oracles
    mapping(address => uint256) quorum;    //oracles which will query the answer (1=oracle hasn't voted, 2=oracle has voted)
  }

  //event that triggers oracle outside of the blockchain
  event NewRequest (
    uint256 id,
    string urlToQuery,
    string attributeToFetch
  );

  //triggered when there's a consensus on the final result
  event UpdatedRequest (
    uint256 id,
    string urlToQuery,
    string attributeToFetch,
    string agreedValue
  );

  event DeletedRequest (
    uint256 id
  );

  constructor() internal {
    requests.push(Request(0, "", "", "", 0, 0));
  }

  function getReputationStatus () public view returns (uint256, uint256, uint256, uint256)
  {
    Reputation.reputation storage datum = oracles[msg.sender];
    return (datum.totalAssignedRequest, datum.totalCompletedRequest, datum.totalAcceptedRequest, datum.totalResponseTime);
  }

  function newOracle () public
  {
    uint256 oracleCount = oracleAddresses.length;
    address sender = msg.sender;
    require(oracleCount < totalOracleCount, "The maximum limit of Oracles is exceeded.");
    require(oracles[sender].addr == address(0), "The oracle is already existed.");

    oracles[sender].addr = sender;
    oracles[sender].totalAssignedRequest = 0;
    oracles[sender].totalCompletedRequest = 0;
    oracles[sender].totalAcceptedRequest = 0;
    oracles[sender].totalResponseTime = 0;
    oracles[sender].lastActiveTime = block.timestamp;
    oracles[sender].score = 1;
    oracleAddresses.push(sender);
  }

  function removeOracleByAddress (address addr) internal
  {
    // require(msg.sender == administrator, "You have to be an administrator.");
    uint256 oracleCount = oracleAddresses.length;

    for (uint256 i = 0; i < oracleCount ; i ++) {
      if (oracleAddresses[i] == addr) {
        oracleAddresses[i] = oracleAddresses[oracleCount - 1];
        delete oracleAddresses[oracleCount - 1];
        oracleAddresses.length --;

        oracles[addr].addr = address(0);      // Reset reputation of oracle to zero
        break;
      }
    }
  }

  function createRequest (
    string memory _urlToQuery,
    string memory _attributeToFetch
  )
  public
  {
    uint256 length = requests.push(Request(currentId, _urlToQuery, _attributeToFetch, "", block.timestamp, 0));
    Request storage r = requests[length-1];

    //Validate all oracles' acitivity
    uint i = 0;
    while (i < oracleAddresses.length) {
      address cursorAddress = oracleAddresses[i];
      if (Reputation.activityValidate(oracles[cursorAddress]) == 0) {
        
        //Remove invalide oracle
        oracleAddresses[i] = oracleAddresses[oracleAddresses.length - 1];
        delete oracleAddresses[oracleAddresses.length - 1];
        oracleAddresses.length --;

        oracles[cursorAddress].addr = address(0);      // Reset reputation of oracle to zero
        i --;
      }
      i ++;
    }

    uint256 oracleCount = oracleAddresses.length;
    uint256[] memory selectedOracles = Selection.getSelectedOracles(oracleCount, oracleCount.mul(2).div(3));
    uint256 scoreSum = 0;

    for (i = 0; i < selectedOracles.length ; i ++) {
      address selectedOracle = oracleAddresses[selectedOracles[i]];
      r.quorum[selectedOracle] = 1;
      scoreSum = scoreSum.add(oracles[selectedOracle].score);
      oracles[selectedOracle].totalAssignedRequest ++;
    }
    r.minQuorum = scoreSum.mul(2).div(3);          //minimum number of responses to receive before declaring final result(2/3 of total)

    // launch an event to be detected by oracle outside of blockchain
    emit NewRequest (
      currentId,
      _urlToQuery,
      _attributeToFetch
    );

    // increase request id
    currentId++;
  }

  //delete peding request
  function deleteRequest (uint256 _id) public {
    delete requests[_id];
    emit DeletedRequest(_id);
  }

  //called by the oracle to record its answer
  function updateRequest (
    uint256 _id,
    string memory _valueRetrieved
  ) public {

    for (uint256 i = 0 ; i < maxResolvedCount ; i ++) {
      require(resolvedRequest[i] != _id, "This request is already resolved.");
    }

    Request storage currRequest = requests[_id];

    uint256 responseTime = block.timestamp.sub(currRequest.timestamp);
    require(responseTime < EXPIRY_TIME, "Your answer is expired.");

    //update last active time
    oracles[address(msg.sender)].lastActiveTime = block.timestamp;

    uint256 oracleCount = oracleAddresses.length;

    //check if oracle is in the list of trusted oracles
    //and if the oracle hasn't voted yet
    if(currRequest.quorum[address(msg.sender)] == 1){

      oracles[address(msg.sender)].totalCompletedRequest ++;
      oracles[address(msg.sender)].totalResponseTime += responseTime;

      //marking that this address has voted
      currRequest.quorum[msg.sender] = 2;

      //save the retrieved value
      currRequest.anwers[address(msg.sender)] = _valueRetrieved;

      uint256 currentQuorum = 0;

      //iterate through oracle list and check if enough oracles(minimum quorum)
      //have voted the same answer has the current one
      for(uint256 i = 0; i < oracleCount; i++){
        bytes memory a = bytes(currRequest.anwers[oracleAddresses[i]]);
        bytes memory b = bytes(_valueRetrieved);

        if(keccak256(a) == keccak256(b)){
          currentQuorum = currentQuorum.add(oracles[oracleAddresses[i]].score);
        }
      }

      //request Resolved
      if(currentQuorum >= currRequest.minQuorum){

        resolvedRequest[cursorResolvedRequest] = currRequest.id;
        cursorResolvedRequest = (cursorResolvedRequest + 1).mod(maxResolvedCount);

        for(uint256 i = 0; i < oracleCount; i++){
          bytes memory a = bytes(currRequest.anwers[oracleAddresses[i]]);
          bytes memory b = bytes(_valueRetrieved);

          if(keccak256(a) == keccak256(b)){
            // accepted oracle
            oracles[oracleAddresses[i]].totalAcceptedRequest ++;
          }

          // update the reputation score of the oracle
          oracles[oracleAddresses[i]].score = Reputation.calculateScore(oracles[oracleAddresses[i]]);
        }

        currRequest.agreedValue = _valueRetrieved;
        emit UpdatedRequest (
          currRequest.id,
          currRequest.urlToQuery,
          currRequest.attributeToFetch,
          currRequest.agreedValue
        );
      }

    }
  }
}
