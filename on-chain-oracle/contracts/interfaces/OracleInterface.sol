// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

interface OracleInterface {
    struct Request {
        uint256 id;                            //request id
        string urlToQuery;
        string attributeToFetch;
        string agreedValue;                 //value from key
        uint timestamp;                     //Request Timestamp
        uint minQuorum;                     //minimum number of responses to receive before declaring final result
        uint256 fee;                            //transaction fee
        uint selectedOracleCount;                //selected oracle count
        mapping(address => string) anwers;     //answers provided by the oracles
        mapping(address => uint256) quorum;    //oracles which will query the answer (1=oracle hasn't voted, 2=oracle has voted)
    }

    struct reputation {
        address addr;
        uint256 totalAssignedRequest;        //total number of past requests that an oracle has agreed to, both fulfilled and unfulfileed
        uint256 totalCompletedRequest;       //total number of past requests that an oracle has fulfileed
        uint256 totalAcceptedRequest;        //total number of requests that have been accepted
        uint256 totalResponseTime;           //total seconds of response time
        uint lastActiveTime;              //last active time of the oracle as second
        uint256 penalty;                     //amount of penalty payment
        uint256 totalEarned;                 //total earned
    }

    event NewRequest(uint256 id, string urlToQuery, string attributeToFetch);
    event UpdatedRequest(uint256 id, string urlToQuery, string attributeToFetch, string agreedValue);
    event DeletedRequest(uint256 id);

    function newOracle() external;
    function createRequest(string calldata urlToQuery, string calldata attributeToFetch) external;
    function updateRequest(uint256 _id, string calldata _valueRetrieved) external;
}