// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

interface OracleInterface {
    struct Request {
        uint256 id;                            //request id
        string queries;
        uint8 qtype;                        //0: data query, 1: price
        address contractAddr;               // contract to save result
        string agreedValue;                 //value from key
        int256 agreedPrice;
        uint256 timestamp;                     //Request Timestamp
        uint minQuorum;                     //minimum number of responses to receive before declaring final result
        uint256 fee;                            //transaction fee
        uint selectedOracleCount;                //selected oracle count
        mapping(address => string) answers;     //answers provided by the oracles
        mapping(address => int256) priceAnswers;     //answers provided by the oracles
        mapping(address => uint256) quorum;    //oracles which will query the answer (1=oracle hasn't voted, 2=oracle has voted)
    }

    struct reputation {
        string name;
        address addr;
        uint256 totalAssignedRequest;        //total number of past requests that an oracle has agreed to, both fulfilled and unfulfileed
        uint256 totalCompletedRequest;       //total number of past requests that an oracle has fulfileed
        uint256 totalAcceptedRequest;        //total number of requests that have been accepted
        uint256 totalResponseTime;           //total seconds of response time
        uint256 lastActiveTime;              //last active time of the oracle as second
        uint256 penalty;                     //amount of penalty payment
        uint256 totalEarned;                 //total earned
    }

    event NewOracle(address addr);
    event NewRequest(uint256 id, string queries, uint8 qtype);
    event UpdatedRequest(uint256 id, string queries, uint8 qtype, string agreedValue, int256 agreedPrice);
    event DeletedRequest(uint256 id);

    function newOracle(string calldata name) external;
    function createRequest(string calldata queries, uint8 qtype, address contractAddr) external;
    function updateRequest(uint256 _id, string calldata _valueRetrieved, int256 _priceRetrieved) external;
}