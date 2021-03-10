// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

import "./interfaces/IDataQuery.sol";
import "./library/Ownable.sol";

contract DataQuery is Ownable, IDataQuery {

  string public feedName;
  mapping(uint256 => requestAnswer) public answers;
  uint256 currentId;

  constructor (string memory _feedName) public {
    feedName = _feedName;
  }
  
  function getLatestAnswer () public override(IDataQuery) returns (string memory)
  {
    require(currentId > 0, "Contract is empty.");
    return answers[currentId - 1].answer;
  }

  function getLatestTimestamp() public override(IDataQuery) returns (uint256)
  {
    require(currentId > 0, "Contract is empty.");
    return answers[currentId - 1].timestamp;
  }

  function getTimestamp(uint256 _id) public override(IDataQuery) returns (uint256)
  {
    require(currentId > _id, "Id is not exist.");
    return answers[_id].timestamp;
  }

  function getAnswer(uint256 _id) public override(IDataQuery) returns (string memory)
  {
    require(currentId > _id, "Id is not exist.");
    return answers[_id].answer;
  }

  function addRequestAnswer(string memory _answer) public override(IDataQuery)
  {
    answers[currentId] = requestAnswer(
      currentId, block.timestamp, _answer
    );
    currentId ++;
  }
}
