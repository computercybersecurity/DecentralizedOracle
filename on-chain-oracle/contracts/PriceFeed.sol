// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

import "./interfaces/IPriceFeed.sol";
import "./library/Ownable.sol";

contract PriceFeed is Ownable, IPriceFeed {

  string public feedName;
  mapping(uint256 => requestAnswer) public answers;
  uint256 currentId;

  constructor (string memory _feedName) public {
    feedName = _feedName;
  }
  
  function getLatestAnswer () public override(IPriceFeed) returns (int256)
  {
    require(currentId > 0, "Contract is empty.");
    return answers[currentId - 1].priceAnswer;
  }

  function getLatestTimestamp() public override(IPriceFeed) returns (uint256)
  {
    require(currentId > 0, "Contract is empty.");
    return answers[currentId - 1].timestamp;
  }

  function getTimestamp(uint256 _id) public override(IPriceFeed) returns (uint256)
  {
    require(currentId > _id, "Id is not exist.");
    return answers[_id].timestamp;
  }

  function getAnswer(uint256 _id) public override(IPriceFeed) returns (int256)
  {
    require(currentId > _id, "Id is not exist.");
    return answers[_id].priceAnswer;
  }

  function addRequestAnswer(int256 _priceAnswer) public override(IPriceFeed)
  {
    answers[currentId] = requestAnswer(
      currentId, block.timestamp, _priceAnswer
    );
    currentId ++;
  }
}
