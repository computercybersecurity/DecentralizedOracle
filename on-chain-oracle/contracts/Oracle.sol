pragma solidity >=0.4.21 <0.6.0;

import "./Selection.sol";

contract Oracle {
  Selection public selection;

  Request[] requests; //list of requests made to the contract
  uint currentId = 0; //increasing request id
  uint minQuorum = 2; //minimum number of responses to receive before declaring final result
  uint totalOracleCount = 3; // Hardcoded oracle count
  mapping(address => Reputation) oracles;
  address[] oracleAddresses;
  address administrator = address(0xafec828FF5BD140FfB42a251AD7435155E7b29bd);

  // defines a general api request
  struct Request {
    uint id;                            //request id
    string urlToQuery;                  //API url
    string attributeToFetch;            //json attribute (key) to retrieve in the response
    string agreedValue;                 //value from key
    mapping(uint => string) anwers;     //answers provided by the oracles
    mapping(address => uint) quorum;    //oracles which will query the answer (1=oracle hasn't voted, 2=oracle has voted)
  }

  struct Reputation {
    address addr;
    uint totalAssignedRequest;        //total number of past requests that an oracle has agreed to, both fulfilled and unfulfileed
    uint totalCompletedRequest;       //total number of past requests that an oracle has fulfileed
    uint totalAcceptedRequest;        //total number of requests that have been accepted
    uint amountPenalty;               //amount of penalty payments
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

  function getReputationStatus () public view returns (uint totalAssignedRequest, uint totalCompletedRequest, uint totalAcceptedRequest, uint amountPenalty)
  {
    Reputation storage datum = oracles[msg.sender];
    return (datum.totalAssignedRequest, datum.totalCompletedRequest, datum.totalAcceptedRequest, datum.amountPenalty);
  }

  function newOracle () public
  {
    uint oracleCount = oracleAddresses.length;
    require(oracleCount < totalOracleCount, "The maximum limit of Oracles is exceeded.");

    address sender = msg.sender;
    if (oracles[sender].addr != address(0)) {
      oracles[sender].addr = sender;
      oracles[sender].totalAssignedRequest = 0;
      oracles[sender].totalCompletedRequest = 0;
      oracles[sender].totalAcceptedRequest = 0;
      oracles[sender].amountPenalty = 0;
      oracleAddresses.push(sender);
    }
  }

  function removeOracle (address addr) public
  {
    require(msg.sender == administrator, "You have to be an administrator.");
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
    uint length = requests.push(Request(currentId, _urlToQuery, _attributeToFetch, ""));
    Request storage r = requests[length-1];

    uint oracleCount = oracleAddresses.length;

    uint[] memory selectedOracles = selection.getSelectedOracles(oracleCount, (oracleCount * 2) / 3);
    uint i = 0;

    for (; i < selectedOracles.length ; i ++) {
      r.quorum[oracleAddresses[selectedOracles[i]]] = 1;
    }

    // launch an event to be detected by oracle outside of blockchain
    emit NewRequest (
      currentId,
      _urlToQuery,
      _attributeToFetch
    );

    // increase request id
    currentId++;
  }

  //called by the oracle to record its answer
  function updateRequest (
    uint _id,
    string memory _valueRetrieved
  ) public {

    Request storage currRequest = requests[_id];
    uint oracleCount = oracleAddresses.length;

    //check if oracle is in the list of trusted oracles
    //and if the oracle hasn't voted yet
    if(currRequest.quorum[address(msg.sender)] == 1){

      //marking that this address has voted
      currRequest.quorum[msg.sender] = 2;

      //iterate through "array" of answers until a position if free and save the retrieved value
      uint tmpI = 0;
      bool found = false;
      while(!found) {
        //find first empty slot
        if(bytes(currRequest.anwers[tmpI]).length == 0){
          found = true;
          currRequest.anwers[tmpI] = _valueRetrieved;
        }
        tmpI++;
      }

      uint currentQuorum = 0;

      //iterate through oracle list and check if enough oracles(minimum quorum)
      //have voted the same answer has the current one
      for(uint i = 0; i < oracleCount; i++){
        bytes memory a = bytes(currRequest.anwers[i]);
        bytes memory b = bytes(_valueRetrieved);

        if(keccak256(a) == keccak256(b)){
          currentQuorum++;
          if(currentQuorum >= minQuorum){
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
  }
}
