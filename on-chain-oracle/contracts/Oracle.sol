pragma solidity >=0.4.21 <0.6.0;

import "./Selection.sol";

contract Oracle {
  Selection public selection;

  Request[] requests; //list of requests made to the contract
  uint currentId = 1; //increasing request id
  uint totalOracleCount = 3; // Hardcoded oracle count
  mapping(address => Reputation) oracles;
  address[] oracleAddresses;
  address administrator = address(0xafec828FF5BD140FfB42a251AD7435155E7b29bd);
  uint maxResolvedCount = 1000;
  uint[] resolvedRequest = new uint[](maxResolvedCount);
  uint cursorResolvedRequest = 0;

  // defines a general api request
  struct Request {
    uint id;                            //request id
    string urlToQuery;                  //API url
    string attributeToFetch;            //json attribute (key) to retrieve in the response
    string agreedValue;                 //value from key
    uint timestamp;                     //Request Timestamp
    uint minQuorum;                     //minimum number of responses to receive before declaring final result
    mapping(address => string) anwers;     //answers provided by the oracles
    mapping(address => uint) quorum;    //oracles which will query the answer (1=oracle hasn't voted, 2=oracle has voted)
  }

  struct Reputation {
    address addr;
    uint totalAssignedRequest;        //total number of past requests that an oracle has agreed to, both fulfilled and unfulfileed
    uint totalCompletedRequest;       //total number of past requests that an oracle has fulfileed
    uint totalAcceptedRequest;        //total number of requests that have been accepted
    uint totalResponseTime;           //total seconds of response time
    uint lastActiveTime;              //last active time of the oracle as second
    uint score;                       //reputation score
  }

  //event that triggers oracle outside of the blockchain
  event NewRequest (
    uint id,
    string urlToQuery,
    string attributeToFetch
  );

  //triggered when there's a consensus on the final result
  event UpdatedRequest (
    uint id,
    string urlToQuery,
    string attributeToFetch,
    string agreedValue
  );

  event DeletedRequest (
    uint id
  );

  constructor() internal {
    requests.push(Request(0, "", "", "", 0, 0));
  }

  function getReputationStatus () public view returns (uint, uint, uint, uint)
  {
    Reputation storage datum = oracles[msg.sender];
    return (datum.totalAssignedRequest, datum.totalCompletedRequest, datum.totalAcceptedRequest, datum.totalResponseTime);
  }

  function newOracle () public
  {
    uint oracleCount = oracleAddresses.length;
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

  function removeOracle (address addr) internal
  {
    // require(msg.sender == administrator, "You have to be an administrator.");
    uint i = 0;
    uint oracleCount = oracleAddresses.length;

    for (; i < oracleCount ; i ++) {
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
    uint length = requests.push(Request(currentId, _urlToQuery, _attributeToFetch, "", block.timestamp, 0));
    Request storage r = requests[length-1];

    uint oracleCount = oracleAddresses.length;

    uint[] memory selectedOracles = selection.getSelectedOracles(oracleCount, (oracleCount * 2) / 3);
    uint i = 0;
    uint scoreSum = 0;

    for (; i < selectedOracles.length ; i ++) {
      address selectedOracle = oracleAddresses[selectedOracles[i]];
      r.quorum[selectedOracle] = 1;
      scoreSum += oracles[selectedOracle].score;
      oracles[selectedOracle].totalAssignedRequest ++;
    }
    r.minQuorum = scoreSum * 2 / 3;          //minimum number of responses to receive before declaring final result(2/3 of total)

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
  function deleteRequest (uint _id) public {
    delete requests[_id];
    emit DeletedRequest(_id);
  }

  //called by the oracle to record its answer
  function updateRequest (
    uint _id,
    string memory _valueRetrieved
  ) public {

    for (uint i = 0 ; i < maxResolvedCount ; i ++) {
      require(resolvedRequest[i] != _id, "This request is already resolved.");
    }

    //update last active time
    oracles[address(msg.sender)].lastActiveTime = block.timestamp;

    Request storage currRequest = requests[_id];
    uint oracleCount = oracleAddresses.length;

    //check if oracle is in the list of trusted oracles
    //and if the oracle hasn't voted yet
    if(currRequest.quorum[address(msg.sender)] == 1){

      oracles[address(msg.sender)].totalCompletedRequest ++;

      //marking that this address has voted
      currRequest.quorum[msg.sender] = 2;

      //save the retrieved value
      currRequest.anwers[address(msg.sender)] = _valueRetrieved;

      uint currentQuorum = 0;

      //iterate through oracle list and check if enough oracles(minimum quorum)
      //have voted the same answer has the current one
      for(uint i = 0; i < oracleCount; i++){
        bytes memory a = bytes(currRequest.anwers[oracleAddresses[i]]);
        bytes memory b = bytes(_valueRetrieved);

        if(keccak256(a) == keccak256(b)){
          currentQuorum += oracles[oracleAddresses[i]].score;
        }
      }

      //request Resolved
      if(currentQuorum >= currRequest.minQuorum){

        resolvedRequest[cursorResolvedRequest] = currRequest.id;
        cursorResolvedRequest = (cursorResolvedRequest + 1) % maxResolvedCount;

        for(uint i = 0; i < oracleCount; i++){
          bytes memory a = bytes(currRequest.anwers[oracleAddresses[i]]);
          bytes memory b = bytes(_valueRetrieved);

          if(keccak256(a) == keccak256(b)){
            oracles[oracleAddresses[i]].totalAcceptedRequest ++;
          }
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
