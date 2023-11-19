// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;


contract DAO {
    struct Proposal {
        uint id;
        string name;
        uint amount;
        address payable recipient;
        uint votes;
        uint end;
        bool executed;
    }
    mapping(uint => Proposal) public proposals;
    mapping(address => mapping(uint => bool)) public votes;
    uint public nextProposalId;
    uint public voteTime;
    uint public quorum;
    address public admin;

    mapping(address => bool) public investors;
    mapping(address => uint) public shares;
    uint public totalShares;
    uint public availableFunds;
    uint public contributionEnd;

    constructor(
        uint contributionTime, 
        uint _voteTime,
        uint _quorum,
        address _admin) {
            require(_quorum > 0 && _quorum < 100, 'quorum must be between 0 and 100');
            contributionEnd = block.timestamp + contributionTime;
            voteTime = _voteTime;
            quorum = _quorum;
            admin = _admin;
    }

    function contribute() payable external {
        require(block.timestamp < contributionEnd, 'cannot contribute after contributions end');
        investors[msg.sender] = true;
        shares[msg.sender] += msg.value;
        totalShares += msg.value;
        availableFunds += msg.value;
    }

    function redeemShare(uint amount) external {
        require(shares[msg.sender] >= amount, 'not enough shares');
        require(availableFunds >= amount, 'not enough available funds');
        shares[msg.sender] -= amount;
        availableFunds -= amount;
        payable(msg.sender).transfer(amount);
    }

    function transferShare(uint amount, address to) external {
        require(shares[msg.sender] >= amount, 'not enough shares');
        shares[msg.sender] -= amount;
        shares[to] += amount;
        investors[to] = true;
    }

    function createProposal(
        string memory name,
        uint amount,
        address payable recipient)
        external onlyInvestor() {
            require(availableFunds >= amount, 'amount too big');
            proposals[nextProposalId] = Proposal(
                nextProposalId,
                name,
                amount,
                recipient,
                0,
                block.timestamp + voteTime,
                false
            );
        availableFunds -= amount;
        nextProposalId++;
    }

    function vote(uint proposalId) external onlyInvestor() {
        Proposal storage proposal = proposals[proposalId];
        require(votes[msg.sender][proposalId] == false, 'investor can only vote once for a proposal');
        require(block.timestamp < proposal.end, 'can only vote until proposal end');
        votes[msg.sender][proposalId] = true;
        proposal.votes += shares[msg.sender];
    }

    modifier onlyInvestor() {
        require(investors[msg.sender] == true, 'only investors');
        _;
    }

    function executeProposal(uint proposalId) external onlyAdmin() {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.end, 'cannot execute a proposal before end');
        require(proposal.executed == false, 'cannot execute a proposal already executed');
        require((proposal.votes * 100) / totalShares >= quorum, 'cannot execute proposal with votes below quorum');
        _transferEther(proposal.amount, proposal.recipient);
        proposal.executed = true;
    }

    function withdrawEther(uint amount, address payable to) external onlyAdmin() {
        _transferEther(amount, to);
    }

    fallback() payable external {
        availableFunds += msg.value;
    }
    
    receive() external payable {
        availableFunds += msg.value;
    }

    function _transferEther(uint amount, address payable to) internal {
        require(amount <= availableFunds, 'not enough available funds');
        availableFunds -= amount;
        to.transfer(amount);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'only admin');
        _;
    }
    
}