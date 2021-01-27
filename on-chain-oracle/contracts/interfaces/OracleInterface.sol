// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

interface OracleInterface {
    //event that triggers oracle outside of the blockchain
    event NewRequest(uint256 id, string requestType, string urlToQuery, string requestMethod, string requestBody, string attributeToFetch);
    //triggered when there's a consensus on the final result
    event UpdatedRequest(uint256 id, string requestType, string urlToQuery, string requestMethod, string requestBody, string attributeToFetch, string agreedValue, uint256 agreedPrice);
    event DeletedRequest(uint256 id);

    function newOracle() external;
    function createRequest(string calldata _requestType, string calldata _urlToQuery, string calldata _requestMethod, string calldata _requestBody, string calldata _attributeToFetch) external;
    function deleteRequest(uint256 _id) external;
    function updateRequest(uint256 _id, string calldata _valueRetrieved, uint256 _priceRetrieved) external;
}