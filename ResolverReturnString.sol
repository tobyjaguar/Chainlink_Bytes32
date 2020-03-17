//Kovan Network
pragma solidity >=0.4.24 <0.6.0;

import "https://github.com/smartcontractkit/chainlink/blob/develop/evm-contracts/src/v0.4/ChainlinkClient.sol";

contract ResolverReturnString is ChainlinkClient {
  address public owner; //only for testing
  bytes32 public lastId; //for testing
  bytes32 public lastPrice; //for testing
  bytes32 public result;
  string public dataSource;
  string public underlying;
  string public oracleService;
  string public endpoint; //https://drand.zerobyte.io:8888/api/public/308000
  string public path; //"randomness.point"

  bytes32 public jobId; //50fc4215f89443d185b061e5d7af9490
  address public oracleAddress; // 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e
  address public LINKTokenAddress; // 0xa36085F69e2889c224210F603D836748e7dC0088

  struct Request {
    address requester;
    address payee;
    uint256 tokenId;
  }

  mapping(bytes32 => Request) public requests;
  mapping(bytes32 => address) public callers;

  constructor(
    string memory _dataSource,
    string memory _underlying,
    string memory _oracleService,
    string memory _endpoint,
    string memory _path,
    address _oracleAddress,
    address _LinkTokenAddress
  )
    public
  {
    owner = msg.sender;
    dataSource = _dataSource;
    underlying = _underlying;
    oracleService = _oracleService;
    jobId = "50fc4215f89443d185b061e5d7af9490";
    endpoint = _endpoint;
    path = _path;
    oracleAddress = _oracleAddress;
    LINKTokenAddress = _LinkTokenAddress;
    setChainlinkToken(_LinkTokenAddress);
  }

  function fetchData(address _funder, uint256 _oracleFee, uint256 _tokenId)
    public
    returns (bool)
  {
    require(
      address(LINKTokenAddress).call(
        bytes4(
          keccak256("transferFrom(address,address,uint256)")),
          _funder,
          address(this),
          _oracleFee
      )
    );
    Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.getPriceCallback.selector);
    req.add("get", endpoint);
    req.add("path", path);
    //req.addInt("times", 100);
    bytes32 requestId = sendChainlinkRequestTo(oracleAddress, req, _oracleFee);
    requests[requestId] = Request({
      requester: msg.sender,
      payee: _funder,
      tokenId: _tokenId
      });
    lastId = requestId;
    callers[requestId] = msg.sender;
    return true;

  }

  function getPriceCallback(bytes32 _requestId, bytes32 _result)
    public
    //recordChainlinkFulfillment(_requestId)
    returns (bool)
  {
    lastPrice = _result;
    (bool success, ) = address(requests[_requestId].requester).call(
      abi.encodeWithSignature(
        "_callback(uint256,bytes32)",
        requests[_requestId].tokenId,
        _result
      )
    );
    require(success);
    return true;
  }

  /**
  ** For local testing
  **/
  function generateId()
    internal
    view
    returns (bytes32)
  {
    return bytes32(block.timestamp);
  }

  function getOwner()
    public
    view
    returns (address)
  {
    return owner;
  }

  function getAddress()
    public
    view
    returns (address)
  {
    return address(this);
  }

  function kill()
    public
  {
    require(msg.sender == owner);
    selfdestruct(owner);
  }
}
