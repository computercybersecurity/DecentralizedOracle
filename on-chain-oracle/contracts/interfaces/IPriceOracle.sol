// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

interface IPriceOracle {
    struct Request {
        uint256 id;                            //request id
        uint256 timestamp;                     //Request Timestamp
        uint256 minQuorum;                     //minimum number of responses to receive before declaring final result
        uint256 selectedOracleCount;                //selected oracle count
        int256 agreedPrice;
        bool isFinished;
        address contractAddr;               // contract to save result
        string queries;
        mapping(address => int256) priceAnswers;     //answers provided by the oracles
        mapping(address => uint256) quorum;    //oracles which will query the answer (1=oracle hasn't voted, 2=oracle has voted)
    }

    struct reputation {
        bytes32 name;
        address addr;
        uint256 totalAssignedRequest;        //total number of past requests that an oracle has agreed to, both fulfilled and unfulfileed
        uint256 totalCompletedRequest;       //total number of past requests that an oracle has fulfileed
        uint256 totalAcceptedRequest;        //total number of requests that have been accepted
        uint256 totalResponseTime;           //total seconds of response time
        uint256 lastActiveTime;              //last active time of the oracle as second
        uint256 totalEarned;                 //total earned
    }

    event NewRequest(uint256 id, string queries, address contractAddr);
    event UpdatedPrice(uint256 id, int256 agreedPrice, address contractAddr);
    event DeletedRequest(uint256 id);

    function createRequest(string calldata queries, address contractAddr) external;
    function updateRequest(uint256 _id, int256 _priceRetrieved) external;
}