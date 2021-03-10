// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

interface IDataQuery {

  struct requestAnswer {
      uint256 id;
      uint256 timestamp;
      string answer;
  }

  function getLatestAnswer() external returns (string memory);
  function getLatestTimestamp() external returns (uint256);
  function getTimestamp(uint256 _id) external returns (uint256);
  function getAnswer(uint256 _id) external returns (string memory);
  function addRequestAnswer(string calldata _answer) external;
}
