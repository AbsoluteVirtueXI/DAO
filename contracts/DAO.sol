//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "./Gouverno.sol";

//1000000000000000000000

contract DAO is IERC777Recipient {
    using Counters for Counters.Counter;

    enum Vote {
        Yes,
        No
    }
    enum Status {
        Inactive,
        Running,
        Approved,
        Rejected
    }

    struct Proposal {
        Status status;
        address proposer;
        uint256 createdAt;
        uint256 nbYes;
        uint256 nbNo;
        string proposition;
    }

    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    uint256 public constant TIME_LIMIT = 1 minutes;
    uint256 public constant MIN_BALANCE_PROPOSE = 1000 * 10**18;
    IERC777 private _gouverno;
    Counters.Counter private _id;
    mapping(uint256 => Proposal) private _proposals;
    mapping(address => mapping(uint256 => bool)) private _hasVote;
    mapping(address => uint256) private _votesBalances;

    constructor() {
        _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        address[] memory defaultOperators_ = new address[](1);
        defaultOperators_[0] = address(this);
        _gouverno = new Gouverno(defaultOperators_);
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {}

    function deposit(uint256 amount) public {
        _votesBalances[msg.sender] += amount;
        _gouverno.operatorSend(msg.sender, address(this), amount, "", "");
    }

    function withdraw(uint256 amount) public {
        require(_votesBalances[msg.sender] >= amount, "DAO: amount exceed balance");
        _votesBalances[msg.sender] -= amount;
        _gouverno.send(msg.sender, amount, "");
    }

    function propose(string memory proposition) public returns (uint256) {
        require(_votesBalances[msg.sender] >= MIN_BALANCE_PROPOSE, "DAO: Not enough GVNR deposited");
        _id.increment();
        uint256 id = _id.current();
        _proposals[id] = Proposal({
            status: Status.Running,
            proposer: msg.sender,
            createdAt: block.timestamp,
            nbYes: 0,
            nbNo: 0,
            proposition: proposition
        });
        return id;
    }

    function vote(uint256 id, Vote vote_) public {
        require(_hasVote[msg.sender][id] == false, "DAO: Already voted");
        require(_proposals[id].status == Status.Running, "DAO: Not a running proposal");

        if (block.timestamp > _proposals[id].createdAt + TIME_LIMIT) {
            if (_proposals[id].nbYes > _proposals[id].nbNo) {
                _proposals[id].status = Status.Approved;
            } else {
                _proposals[id].status = Status.Rejected;
            }
        } else {
            if (vote_ == Vote.Yes) {
                _proposals[id].nbYes += _votesBalances[msg.sender];
            } else {
                _proposals[id].nbNo += _votesBalances[msg.sender];
            }
            _hasVote[msg.sender][id] = true;
        }
    }

    function proposalById(uint256 id) public view returns (Proposal memory) {
        return _proposals[id];
    }

    function hasVote(address account, uint256 id) public view returns (bool) {
        return _hasVote[account][id];
    }

    function gouverno() public view returns (address) {
        return address(_gouverno);
    }

    function votesBalanceOf(address account) public view returns (uint256) {
        return _votesBalances[account];
    }
}
