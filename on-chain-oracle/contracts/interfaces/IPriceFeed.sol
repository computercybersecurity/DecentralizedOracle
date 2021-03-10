// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

interface IPriceFeed {

  struct requestAnswer {
      uint256 id;
      uint256 timestamp;
      int256 priceAnswer;
  }

  function getLatestAnswer() external returns (int256);
  function getLatestTimestamp() external returns (uint256);
  function getTimestamp(uint256 _id) external returns (uint256);
  function getAnswer(uint256 _id) external returns (int256);
  function addRequestAnswer(int256 _priceAnswer) external;
}
