// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

interface OracleInterface {
    struct RequestParam {
        string urlToQuery;
        string attributeToFetch;
        uint256 decimals;
    }

    //event that triggers oracle outside of the blockchain
    event NewRequest(uint256 id, string requestType, RequestParam[] params);
    //triggered when there's a consensus on the final result
    event UpdatedRequest(uint256 id, string requestType, RequestParam[] params, string agreedValue, uint256 agreedPrice);
    event DeletedRequest(uint256 id);

    function newOracle() external;
    function createRequest(string calldata _requestType, RequestParam[] calldata _params) external;
    function deleteRequest(uint256 _id) external;
    function updateRequest(uint256 _id, string calldata _valueRetrieved, uint256 _priceRetrieved) external;
}