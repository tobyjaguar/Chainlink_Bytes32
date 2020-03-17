pragma solidity >=0.4.24 <0.6.0;

contract StringClient {

    address public owner;
    address public spResolver;
    bytes32 public result;

    event OracleReturned
    (
        address indexed resolver,
        uint256 indexed tokenId,
        bytes32 indexed result
    );

    constructor(address _resolverAddress)
        public
    {
        owner = msg.sender;
        spResolver = _resolverAddress;
    }

    function getPrice(uint256 _oracleFee, uint256 _tokenId)
        public
        returns (bool)
    {
    (bool success, ) = address(spResolver).call(
      abi.encodeWithSignature("fetchData(address,uint256,uint256)", msg.sender, _oracleFee, _tokenId)
    );
    require(success, "fetch success did not return true");

    return true;
  }

    function _callback(
        uint256 _tokenId,
        bytes32 _result
    )
        public
    {
        require(msg.sender == spResolver, "resolve address was not correct"); // MUST restrict a call to only the resolver address
        result = _result;

        emit OracleReturned(
          msg.sender,
          _tokenId,
          _result
        );

    }

    function getResolverAddress()
        public
        view
        returns (address)
    {
        return spResolver;
    }

    function changeResolverAddress(address _newAddress)
        public
        returns (bool)
    {
        require(msg.sender == owner);
        spResolver = _newAddress;
        return true;
    }

    function kill()
        public
    {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}
