// SPDX-License-Identifier: SSPL-1.0
pragma solidity ^0.8.0;

contract LZExecutor is Domain {
    using BoringMath for uint256;
    using BoringMath128 for uint128;

    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    uint256 public override totalSupply;

    IERC20 public immutable token;
    address public operator;

    mapping(address => address) public userVote;
    mapping(address => uint256) public votes;

    constructor(
        string memory sharesSymbol,
        string memory sharesName,
        IERC20 token_,
        address initialOperator
    ) public {
        symbol = sharesSymbol;
        name = sharesName;
        token = token_;
        operator = initialOperator;
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /* prettier-ignore */
    bytes32 private constant PERMIT_SIGNATURE_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

/**{ 


TODO


} */

 event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        bytes data,
        uint256 eta
    );
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        bytes data
    );
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        bytes data
    );

    uint256 public constant GRACE_PERIOD = 14 days;
    uint256 public constant DELAY = 2 days;
    mapping(bytes32 => uint256) public queuedTransactions;

    function queueTransaction(
        address target,
        uint256 value,
        bytes memory data
    ) public returns (bytes32) {
        require(msg.sender == operator, "Operator only");
  //      require(votes[operator] * 2 > totalSupply, "Not enough votes");

        bytes32 txHash = keccak256(abi.encode(target, value, data));
        uint256 eta = block.timestamp + DELAY;
        queuedTransactions[txHash] = eta;

        emit QueueTransaction(txHash, target, value, data, eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint256 value,
        bytes memory data
    ) public {
        require(msg.sender == operator, "Operator only");

        bytes32 txHash = keccak256(abi.encode(target, value, data));
        queuedTransactions[txHash] = 0;

        emit CancelTransaction(txHash, target, value, data);
    }

    function executeTransaction(
        address target,
        uint256 value,
        bytes memory data
    ) public payable returns (bytes memory) {
        require(msg.sender == operator, "Operator only");
     //   require(votes[operator] * 2 > totalSupply, "Not enough votes");

        bytes32 txHash = keccak256(abi.encode(target, value, data));
        uint256 eta = queuedTransactions[txHash];
        require(block.timestamp >= eta, "Too early");
        require(block.timestamp <= eta + GRACE_PERIOD, "Tx stale");

        queuedTransactions[txHash] = 0;

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );
        require(success, "Tx reverted :(");

        emit ExecuteTransaction(txHash, target, value, data);

        return returnData;
    }