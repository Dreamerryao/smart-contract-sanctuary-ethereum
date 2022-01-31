// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./extensions/ERC20Capped.sol";

contract HZT is ERC20Capped{

	struct AddressDetails{
		bool walletBalanceCapExempt;
		bool transactionLimitExcempt;
		bool transferRightRevoked;
		bool voteRightRevoked;
		uint latestVoteExpiryDate;
		bool isLiquidityPool;
		bool isContractRouter;
		uint lastTransferTimeStamp;
		uint256 totalAmountInCharity;
		string signature;
	}

	struct Vote{
		bool voted;
		bool inFavor;
		uint timestamp;
	}

	struct Ballot{
		uint issueId;
		string description;
		uint expiryDate;
		MotionType motionType;
		uint256 motionTargetValue;
		address motionTargetAddress;
		uint motionTargetDate;
		uint256 currentValue;
		uint256 totalWealthInFavor;
		uint256 totalHoldersInFavor;
		uint256 totalWealthAgainst;
		uint256 totalHoldersAgainst;
		address chairperson;
		bool executed;
		bool motionPassed;
		uint256 escrowAmount;
		MotionFailReason executionResultReason;
	}

	struct CharityCause{
		uint256 rate;
		uint expiryDate;
		address collectorAddress;
		uint initiatorBallotId;
	}

	enum MotionType{
		Generic,
		WalletMaxBalance,
		TxMaxValue,
		CreatorBurnRate,
		BallotFee,
		BallotEscrow,
		BallotExpiry,
		BallotExecWindow,
		BallotTotalSupplyExecMargin,
		BallotVoteCountExecMargin,
		BallotInFavExecMargin,
		BallotVoterWealthExecMargin,
		ExemptAddressMaxWalletBalance,
		RevertAddressMaxWalletBalanceExemption,
		ExemptAddressMaxTxValue,
		RevertAddressMaxTxValueExemption,
		RevokeAddressRightToVote,
		GrantAddressRightToVote,
		MintTokensToAddress,
		BurnAmountFromAddress,
		LaunchCharitableEvent,
		SubmitLiquidityPoolAddress,
		RemoveLiquidityPoolAddress,
		SubmitContractRouterAddress,
		RemoveContractRouterAddress,
		DisableVotingSystem
	}

	enum TransactionDirection{
		In,
		Out
	}

	enum MotionFailReason{
		None,
		VoteTurnoutNotMet,
		VoteTurnoutWealthThresholdNotMet,
		VoteTurnoutThresholdNotMet,
		VotesInFavorPercentageNotMet,
		WealthInFavorPercentageNotMet
	}

	uint public _holders;

	address private immutable _creator;
	address private immutable _voteFeeCollector;

	uint256 private _maxTxValue;
	uint256 private _maxWalletBalance;
	uint256 private _creatorBurnRate;
	uint256 private _totalAmountInLiquidityPools;
	uint256 private _totalAmountInAccountsWithoutVoteRight;
	uint private _currentCharityCause;

	uint256 private _ballotFee;
	uint256 private _ballotEscrow;
	uint private _ballotLifespan;
	uint private _BallotExecWindow;
	uint private _ballotLastIssueId; 

	uint256 private _ballotTurnoutWealthThreshold;
	uint256 private _ballotTurnoutThreshold;
	uint256 private _ballotVotesInFavorPercentageThreshold;
	uint256 private _ballotWealthInFavorPercentageThreshold;

	bool private _votingEnabled;
	uint private _minTimeBetweenTransfers;

	mapping(address => AddressDetails) _addressDetails;
	mapping(uint => Ballot) _ballots;
	mapping(address => mapping(MotionType => uint)) _addressVoteTickets;
	mapping(address => mapping(uint => Vote)) _addressVotedBallots;
	mapping(uint => CharityCause) _charityCauses;

	constructor(string memory name,string memory symbol) 		
		ERC20 (name, symbol) 
		ERC20Capped(900000000 * 1 ether)
		{	
			_creator = _msgSender();	
			address voteFeeCollector = 0xF55dd82c8B8668a33acE8A8Cdfa2FE353D690996; // TODO - change to actual sepparate address	
			//TODO transfer funds to collector wallet after minting without restrictions
			_voteFeeCollector = voteFeeCollector;			
			_addressDetails[voteFeeCollector].walletBalanceCapExempt = true;
			_addressDetails[voteFeeCollector].transactionLimitExcempt = true;

			_maxTxValue = 10000000 * 1 ether;
			_maxWalletBalance = 10000000  * 1000 * 1 ether; //remove * 1000 
			_creatorBurnRate = 2;
			
			_ballotLastIssueId = 1;
			_ballotFee = 1000;
			_ballotEscrow = 1000;
			_ballotLifespan = 5;
			_BallotExecWindow = 5;
			_ballotTurnoutWealthThreshold = 5;
			_ballotTurnoutThreshold = 2;
			_ballotVotesInFavorPercentageThreshold = 50;
			_ballotWealthInFavorPercentageThreshold = 50;
		
			_totalAmountInLiquidityPools = 0;
			_totalAmountInAccountsWithoutVoteRight = 0;
			_holders = 1;
			_votingEnabled = true;

			_addressDetails[_msgSender()].transactionLimitExcempt = true;
			_addressDetails[_msgSender()].walletBalanceCapExempt = true;
			_addressDetails[0xf164fC0Ec4E93095b804a4795bBe1e041497b92a].isContractRouter = true; //uniswap v2 router0
			_addressDetails[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D].isContractRouter = true; //uniswap v2 router1
			_addressDetails[0xE592427A0AEce92De3Edee1F18E0157C05861564].isContractRouter = true; //uniswap v3 SwapRouter
			_addressDetails[0x1F98431c8aD98523631AE4a59f267346ea31F984].isContractRouter = true; //uniswap v3 factory
			_addressDetails[0xC36442b4a4522E871399CD717aBDD847Ab11FE88].isContractRouter = true; //uniswap v3 NFP

			_charityCauses[0].rate = 20;
			_charityCauses[0].initiatorBallotId = 0;
			_charityCauses[0].collectorAddress = 0xF55dd82c8B8668a33acE8A8Cdfa2FE353D690996; //change to charity address
			_charityCauses[0].expiryDate = block.timestamp + 90 days;
			_currentCharityCause = 0;
			_addressDetails[_charityCauses[0].collectorAddress].walletBalanceCapExempt = true;
			_addressDetails[_charityCauses[0].collectorAddress].transactionLimitExcempt = true;
			
			ERC20._mint(_msgSender(), 900000000 * 1 ether);

			//transfer funds to moneyholder
		}

	modifier votingEnabled {
       	require(_votingEnabled, "Voting is permanently disabled");
        _;
    } 

	function burn(address recipient, uint256 amount) public returns (bool) {

		super._burn(recipient, amount); 		

		updateHolders(recipient, address(0), amount);

		if (_addressDetails[recipient].latestVoteExpiryDate > block.timestamp)
			updateOutstandingVotes(recipient, amount, TransactionDirection.Out);

		if (_addressDetails[recipient].isLiquidityPool)
			_totalAmountInLiquidityPools -= amount;

		return true;	
	}


	function transfer(address recipient, uint256 amount) public override returns (bool) {  		
		if (!_addressDetails[recipient].isLiquidityPool 
			&& !_addressDetails[_msgSender()].isLiquidityPool) {
			require(_addressDetails[_msgSender()].lastTransferTimeStamp + _minTimeBetweenTransfers * 1 seconds < block.timestamp,
					"Minimum time between transfers not elapsed");
		}	

		if (!_addressDetails[recipient].walletBalanceCapExempt 
			&& !_addressDetails[_msgSender()].isContractRouter 
			&& !_addressDetails[recipient].isLiquidityPool 
			&& !_addressDetails[recipient].isContractRouter){
			require(balanceOf(recipient) + amount <= _maxWalletBalance, 
					"Transaction will cause address to exceed maximum balance");
		}			

		if (!_addressDetails[recipient].transactionLimitExcempt 
			&& !_addressDetails[_msgSender()].isContractRouter
			&& !_addressDetails[recipient].isLiquidityPool 
			&& !_addressDetails[recipient].isContractRouter){
			require(amount <= _maxTxValue, "Transaction amount exceeds the maximum transaction value");
		}
			
		if (_addressDetails[_msgSender()].isContractRouter && !_addressDetails[recipient].isLiquidityPool)
			_addressDetails[recipient].isLiquidityPool = true;

		if(_charityCauses[_currentCharityCause].expiryDate > block.timestamp
			&& !_addressDetails[recipient].isContractRouter && !_addressDetails[recipient].isLiquidityPool && !_addressDetails[_msgSender()].isContractRouter){
				uint256 amountToDonate = _charityCauses[_currentCharityCause].rate * amount / 10000;
				_addressDetails[_msgSender()].totalAmountInCharity += amountToDonate;
				_transfer(_msgSender(), recipient, amount - amountToDonate);
				_transfer(_msgSender(), _charityCauses[_currentCharityCause].collectorAddress, amountToDonate);
				_afterTransferActions(recipient, _msgSender(), amount - amountToDonate);
				_afterTransferActions(_charityCauses[_currentCharityCause].collectorAddress, _msgSender(), amountToDonate);
		}else{
				_transfer(_msgSender(), recipient, amount);		
				_afterTransferActions(recipient, _msgSender(), amount);
		}
		
	  
		return true;
    }

	function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {	

		if (!_addressDetails[recipient].isLiquidityPool && !_addressDetails[_msgSender()].isLiquidityPool)
			require(_addressDetails[_msgSender()].lastTransferTimeStamp + _minTimeBetweenTransfers * 1 seconds < block.timestamp, "Minimum time between transfers not elapsed");
	
		if (!_addressDetails[recipient].walletBalanceCapExempt && !_addressDetails[_msgSender()].isContractRouter 
		&& !_addressDetails[recipient].isLiquidityPool && !_addressDetails[recipient].isContractRouter)
			require(balanceOf(recipient) + amount <= _maxWalletBalance, "Transaction will cause address to exceed maximum balance");

		if (!_addressDetails[recipient].transactionLimitExcempt && !_addressDetails[_msgSender()].isContractRouter
		&& !_addressDetails[recipient].isLiquidityPool && !_addressDetails[recipient].isContractRouter)
			require(amount <= _maxTxValue, "Transaction amount exceeds the maximum transaction value");

		if (_addressDetails[_msgSender()].isContractRouter && !_addressDetails[recipient].isLiquidityPool)
			_addressDetails[recipient].isLiquidityPool = true;

		if(!_addressDetails[recipient].isContractRouter && !_addressDetails[recipient].isLiquidityPool 
		&& _charityCauses[_currentCharityCause].expiryDate > block.timestamp){
				uint256 amountToDonate = _charityCauses[_currentCharityCause].rate * amount / 1000;
				_addressDetails[_msgSender()].totalAmountInCharity += amountToDonate;
				super.transferFrom(sender, recipient, amount - amountToDonate);
				_afterTransferActions(recipient, sender, amount - amountToDonate);
				super.transferFrom(sender, _charityCauses[_currentCharityCause].collectorAddress, amountToDonate);
				_afterTransferActions(_charityCauses[_currentCharityCause].collectorAddress, sender, amountToDonate);
			}else{
				super.transferFrom(sender, recipient, amount);
				_afterTransferActions(recipient, sender, amount);
			}

		return true;
    }

	function _afterTransferActions(address recipient, address sender, uint256 amount) private{
	
		updateHolders(sender, recipient, amount);
	
		if (balanceOf(_creator) > 0 && (sender != _creator || recipient != _creator)) {
			uint256 burnAmount = amount * _creatorBurnRate / 1000;
			if (balanceOf(_creator) > burnAmount)
				super._burn(_creator, burnAmount); 
			else
				super._burn(_creator, balanceOf(_creator)); 
		} 

		if (_addressDetails[recipient].isLiquidityPool)
			_totalAmountInLiquidityPools += amount;

		if (_addressDetails[sender].isLiquidityPool)
			_totalAmountInLiquidityPools -= amount;	
	
		if (_addressDetails[recipient].latestVoteExpiryDate > block.timestamp)
			updateOutstandingVotes(recipient, amount, TransactionDirection.Out);

		if (_addressDetails[sender].latestVoteExpiryDate > block.timestamp)
			updateOutstandingVotes(sender, amount, TransactionDirection.Out);

		_addressDetails[sender].lastTransferTimeStamp = block.timestamp;
	}

	function proposeBallot(
		string memory _description, 
		MotionType _motion, 
		uint256 _motionTargetValue, 
		address _motionTargetAddress,
		uint _motionTargetDate
		) public votingEnabled returns(uint) {
	
		uint issueId = _ballotLastIssueId + 1;
		require(_ballots[issueId].chairperson == address(0), "Invalid motion");
		require(balanceOf(_msgSender()) >= _ballotFee + _ballotEscrow, "Not enough balance to cover ballot proposal costs");
		require(!_addressDetails[_msgSender()].voteRightRevoked, "Addresses with revoked voting rights cannot submit new ballots");
		
		if (_motion == MotionType.MintTokensToAddress)
			require(!_addressDetails[_motionTargetAddress].isLiquidityPool, "Cannot mint to liquidity pools");

		if(_motion == MotionType.LaunchCharitableEvent){
			require(_charityCauses[_currentCharityCause].expiryDate < block.timestamp + _ballotLifespan * 1 minutes + _BallotExecWindow * 1 minutes, 
			"Cannot submit charity event motion because the current one is still active");
		}

		if (_ballotFee > 0) {
			_transfer(_msgSender(), _voteFeeCollector, _ballotFee);
		}
		
		if (_ballotEscrow > 0) {
			_transfer(_msgSender(), _voteFeeCollector, _ballotEscrow);
		}
		
		uint256 _currentValue = 0;
		_ballots[issueId] = Ballot({
			issueId : issueId,
			description : _description,
			expiryDate : block.timestamp + _ballotLifespan * 1 minutes,
			motionType : _motion,
			motionTargetValue : _motionTargetValue,
			motionTargetAddress : _motionTargetAddress,
			motionTargetDate : _motionTargetDate,
			currentValue : _currentValue,
			totalWealthInFavor : 0,
			totalHoldersInFavor : 0,
			totalWealthAgainst : 0,
			totalHoldersAgainst : 0,
			chairperson : _msgSender(),
			executed : false,
			motionPassed : false,
			escrowAmount : _ballotEscrow,
			executionResultReason : MotionFailReason.None
		});
		
		_ballotLastIssueId = issueId;

		updateHolders(_msgSender(), _voteFeeCollector, _ballotFee + _ballotEscrow);
		updateOutstandingVotes(_msgSender(), _ballotFee + _ballotEscrow, TransactionDirection.Out);
		return issueId;
	}

	function vote(uint issueId, bool inFavor) public votingEnabled returns(bool) {
		require(_ballots[issueId].expiryDate > block.timestamp, "Ballot expired");
		require(!_addressVotedBallots[_msgSender()][issueId].voted, "Already voted");
		require(!_addressDetails[_msgSender()].voteRightRevoked, "Vote right revoked");
		require(_ballots[_addressVoteTickets[_msgSender()][_ballots[issueId].motionType]].expiryDate < block.timestamp, "Vote ticked type already used");

		_addressVotedBallots[_msgSender()][issueId].voted = true;	
		_addressVotedBallots[_msgSender()][issueId].inFavor = inFavor;	
		_addressVotedBallots[_msgSender()][issueId].timestamp = block.timestamp;	
		_addressVoteTickets[_msgSender()][_ballots[issueId].motionType] = issueId;

		uint expirtyDate = _ballots[issueId].expiryDate + _BallotExecWindow * 1 minutes;
		if (_addressDetails[_msgSender()].latestVoteExpiryDate < expirtyDate)
			_addressDetails[_msgSender()].latestVoteExpiryDate = expirtyDate;

		if (inFavor) {
			_ballots[issueId].totalWealthInFavor += balanceOf(_msgSender());
			_ballots[issueId].totalHoldersInFavor += 1;
		}else{
			_ballots[issueId].totalWealthAgainst += balanceOf(_msgSender());
			_ballots[issueId].totalHoldersAgainst += 1;
		}

		return true;
	}

	function executeBallot(uint issueId) public votingEnabled returns(bool) {	
		require(_ballots[issueId].chairperson == _msgSender() || _msgSender() == _creator, "Ballots can be executed only by their chairperson or creator");
		require(!_ballots[issueId].executed, "Ballot already executed");
		require(_ballots[issueId].expiryDate < block.timestamp, "Vote submission still open");
		require((_ballots[issueId].expiryDate + _BallotExecWindow * 1 minutes > block.timestamp && _msgSender() != _creator)
		|| (_ballots[issueId].expiryDate + _BallotExecWindow * 1 minutes < block.timestamp && _msgSender() == _creator), "Execution window expired");

		_ballots[issueId].executed = true;
		if (balanceOf(_voteFeeCollector) >= _ballots[issueId].escrowAmount) {
			_transfer(_voteFeeCollector, _msgSender(), _ballots[issueId].escrowAmount);
			updateHolders(_voteFeeCollector, _msgSender(), _ballots[issueId].escrowAmount);
		}

		uint256 minimumTurnout = _holders * _ballotTurnoutThreshold / 100;	
		uint256 turnout = _ballots[issueId].totalHoldersInFavor + _ballots[issueId].totalHoldersAgainst;

		if (turnout < minimumTurnout) {
			_ballots[issueId].motionPassed = false;
			_ballots[issueId].executionResultReason = MotionFailReason.VoteTurnoutThresholdNotMet;
			return false;
		}

		uint256 minimumTurnoutWealth = 
									(totalSupply() - _totalAmountInLiquidityPools - _totalAmountInAccountsWithoutVoteRight) 
									* _ballotTurnoutWealthThreshold / 100; 

		if (_ballots[issueId].totalWealthInFavor + _ballots[issueId].totalWealthAgainst < minimumTurnoutWealth) {
			_ballots[issueId].motionPassed = false;
			_ballots[issueId].executionResultReason = MotionFailReason.VoteTurnoutWealthThresholdNotMet;
			return false;
		}
		
		uint256 percentageOfVotesInFavor = _ballots[issueId].totalHoldersInFavor * 100 / turnout; 
		if (percentageOfVotesInFavor < _ballotVotesInFavorPercentageThreshold) {
			_ballots[issueId].motionPassed = false;
			_ballots[issueId].executionResultReason = MotionFailReason.VotesInFavorPercentageNotMet;
			return false;
		}

		uint256 turnoutWealth = _ballots[issueId].totalWealthInFavor + _ballots[issueId].totalWealthAgainst;
		if (turnoutWealth == 0) {
			_ballots[issueId].motionPassed = false;
			_ballots[issueId].executionResultReason = MotionFailReason.VoteTurnoutWealthThresholdNotMet;
			return false;
		}

		uint256 percentageOfWealthInFavor = _ballots[issueId].totalWealthInFavor * 100 / turnoutWealth;
		if (percentageOfWealthInFavor < _ballotWealthInFavorPercentageThreshold) {
			_ballots[issueId].motionPassed = false;
			_ballots[issueId].executionResultReason = MotionFailReason.WealthInFavorPercentageNotMet;
			return false;
		}

		_ballots[issueId].motionPassed = true;
		_ballots[issueId].executionResultReason = MotionFailReason.None;
		performBallotMotionAction(issueId,
			 _ballots[issueId].motionType, 
			 _ballots[issueId].motionTargetValue,
			 _ballots[issueId].motionTargetAddress, 
			 _ballots[issueId].motionTargetDate);

		return true;
	}      

	function setSignature(string memory sig) public returns(bool){
		_addressDetails[_msgSender()].signature = sig;
		return true;
	}

	function performBallotMotionAction(
		uint issueId,
		MotionType motionType, 
		uint256 motionTargetValue,  
		address motionTargetAddress,
		uint motionTargetDate) private{
		
		if (motionType == MotionType.Generic)
			return;

		if(motionType == MotionType.LaunchCharitableEvent){
			uint charityId = _currentCharityCause + 1;
			_charityCauses[charityId].rate = motionTargetValue;
			_charityCauses[charityId].expiryDate = motionTargetDate;
			_charityCauses[charityId].collectorAddress = motionTargetAddress;
			_charityCauses[charityId].initiatorBallotId = issueId;
			_currentCharityCause = charityId;
		}	

		if (motionType == MotionType.WalletMaxBalance) {
			_maxWalletBalance = motionTargetValue;
			return;
		}

		if (motionType == MotionType.TxMaxValue) {
			_maxTxValue = motionTargetValue;
			return;
		}

		if (motionType == MotionType.CreatorBurnRate) {
			_creatorBurnRate = motionTargetValue;
			return;
		}

		if (motionType == MotionType.BallotFee) {
			_ballotFee = motionTargetValue;
			return;
		}

		if (motionType == MotionType.BallotEscrow) {
			_ballotEscrow = motionTargetValue;
			return;
		}

		if (motionType == MotionType.BallotExpiry) {
			_ballotLifespan = motionTargetValue;
			return;
		}

		if (motionType == MotionType.BallotExecWindow) {
			_BallotExecWindow = motionTargetValue;
			return;
		}

		if (motionType == MotionType.BallotTotalSupplyExecMargin) {
			_ballotTurnoutWealthThreshold = motionTargetValue;
			return;
		}

		if (motionType == MotionType.BallotVoteCountExecMargin) {
			_ballotTurnoutThreshold = motionTargetValue;
			return;
		}
		
		if (motionType == MotionType.BallotInFavExecMargin) {
			_ballotVotesInFavorPercentageThreshold = motionTargetValue;
			return;
		}

		if (motionType == MotionType.BallotVoterWealthExecMargin) {
			_ballotWealthInFavorPercentageThreshold = motionTargetValue;
			return;
		}

		if (motionType == MotionType.ExemptAddressMaxWalletBalance) {
			_addressDetails[motionTargetAddress].walletBalanceCapExempt = true;
			return;
		}

		if (motionType == MotionType.RevertAddressMaxWalletBalanceExemption) {
			_addressDetails[motionTargetAddress].walletBalanceCapExempt = false;
			return;
		}

		if (motionType == MotionType.ExemptAddressMaxTxValue) {
			_addressDetails[motionTargetAddress].transactionLimitExcempt = true;
			return;
		}

		if (motionType == MotionType.RevertAddressMaxTxValueExemption) {
			_addressDetails[motionTargetAddress].transactionLimitExcempt = false;
			return;
		}

		if (motionType == MotionType.GrantAddressRightToVote) {
			if (_addressDetails[motionTargetAddress].voteRightRevoked) {
				_addressDetails[motionTargetAddress].voteRightRevoked = false;
				_totalAmountInAccountsWithoutVoteRight -= balanceOf(motionTargetAddress);
			}
			return;
		}

		if (motionType == MotionType.RevokeAddressRightToVote) {
			if (!_addressDetails[motionTargetAddress].voteRightRevoked) {
				_addressDetails[motionTargetAddress].voteRightRevoked = true;
				_totalAmountInAccountsWithoutVoteRight += balanceOf(motionTargetAddress);
			}
		}

		if (motionType == MotionType.MintTokensToAddress) {
			mint(motionTargetAddress, motionTargetValue);
			return;
		}

		if (motionType == MotionType.BurnAmountFromAddress) {
			burn(motionTargetAddress, motionTargetValue);
			return;
		}

		if (motionType == MotionType.SubmitLiquidityPoolAddress) {
			addLiquidityPool(motionTargetAddress);
			return;
		}

		if (motionType == MotionType.RemoveLiquidityPoolAddress) {
			removeLiquidityPool(motionTargetAddress);
			return;
		}		

		if (motionType == MotionType.SubmitContractRouterAddress) {
			_addressDetails[motionTargetAddress].isContractRouter = true;
			return;
		}

		if (motionType == MotionType.RemoveContractRouterAddress) {
			_addressDetails[motionTargetAddress].isContractRouter = false;
			return;
		}		

		if (motionType == MotionType.DisableVotingSystem)
			_votingEnabled = false;
	} 

	function addLiquidityPool(address account) private{
		_addressDetails[account].isLiquidityPool = true;
		_totalAmountInLiquidityPools += balanceOf(account);
	}

	function removeLiquidityPool(address account) private{
		_addressDetails[account].isLiquidityPool = false;
		_totalAmountInLiquidityPools -= balanceOf(account);
	}

	function updateHolders(address sender, address receiver, uint256 amount) private{
		if (balanceOf(receiver) - amount == 0) 
		  	_holders++;
     	if (balanceOf(sender) == 0)
		   	_holders--;
	}

	function updateOutstandingVotes(address voter, uint256 amount, TransactionDirection txDirection) private{
		updateVoteWeight(voter, MotionType.Generic, amount, txDirection);
		updateVoteWeight(voter, MotionType.WalletMaxBalance, amount, txDirection);
		updateVoteWeight(voter, MotionType.TxMaxValue, amount, txDirection);
		updateVoteWeight(voter, MotionType.CreatorBurnRate, amount, txDirection);
		updateVoteWeight(voter, MotionType.BallotFee, amount, txDirection);
		updateVoteWeight(voter, MotionType.BallotEscrow, amount, txDirection);
		updateVoteWeight(voter, MotionType.BallotExpiry, amount, txDirection);
		updateVoteWeight(voter, MotionType.BallotExecWindow, amount, txDirection);
		updateVoteWeight(voter, MotionType.BallotTotalSupplyExecMargin, amount, txDirection);
		updateVoteWeight(voter, MotionType.BallotVoteCountExecMargin, amount, txDirection);
		updateVoteWeight(voter, MotionType.BallotInFavExecMargin, amount, txDirection);
		updateVoteWeight(voter, MotionType.BallotVoterWealthExecMargin, amount, txDirection);
		updateVoteWeight(voter, MotionType.ExemptAddressMaxWalletBalance, amount, txDirection);
		updateVoteWeight(voter, MotionType.RevertAddressMaxWalletBalanceExemption, amount, txDirection);
		updateVoteWeight(voter, MotionType.ExemptAddressMaxTxValue, amount, txDirection);
		updateVoteWeight(voter, MotionType.RevertAddressMaxTxValueExemption, amount, txDirection);
		updateVoteWeight(voter, MotionType.RevokeAddressRightToVote, amount, txDirection);
		updateVoteWeight(voter, MotionType.GrantAddressRightToVote, amount, txDirection);
		updateVoteWeight(voter, MotionType.MintTokensToAddress, amount, txDirection);
		updateVoteWeight(voter, MotionType.BurnAmountFromAddress, amount, txDirection);
		updateVoteWeight(voter, MotionType.SubmitLiquidityPoolAddress, amount, txDirection);
		updateVoteWeight(voter, MotionType.RemoveLiquidityPoolAddress, amount, txDirection);
		updateVoteWeight(voter, MotionType.SubmitContractRouterAddress, amount, txDirection);
		updateVoteWeight(voter, MotionType.RemoveContractRouterAddress, amount, txDirection);
		updateVoteWeight(voter, MotionType.DisableVotingSystem, amount, txDirection);
	}

	function updateVoteWeight(address voter, MotionType motion, uint amount, TransactionDirection txDirection) private {
		if (_ballots[_addressVoteTickets[voter][motion]].expiryDate > block.timestamp) {
			if (_addressVotedBallots[voter][_ballots[_addressVoteTickets[voter][motion]].issueId].voted) {
				if (_addressVotedBallots[voter][_ballots[_addressVoteTickets[voter][motion]].issueId].inFavor) {
					if (txDirection == TransactionDirection.In) {
						_ballots[_addressVoteTickets[voter][motion]].totalWealthInFavor += amount;
					}else{
						_ballots[_addressVoteTickets[voter][motion]].totalWealthInFavor -= amount;
						if (balanceOf(voter) == 0 && _ballots[_addressVoteTickets[voter][motion]].totalHoldersInFavor > 0) {
							_ballots[_addressVoteTickets[voter][motion]].totalHoldersInFavor --;
						}			
					}									
				}else{
					if (txDirection == TransactionDirection.In) {
						_ballots[_addressVoteTickets[voter][motion]].totalWealthAgainst += amount;
					}else{
						_ballots[_addressVoteTickets[voter][motion]].totalWealthAgainst -= amount;
						if (balanceOf(voter) == 0 && _ballots[_addressVoteTickets[voter][motion]].totalHoldersAgainst > 0) {
							_ballots[_addressVoteTickets[voter][motion]].totalHoldersAgainst --;
						}			
					}	
				}
			}
		}
	}

	function mint(address recipient, uint256 amount) private {		
		
		super._mint(recipient, amount);
		
		if (_addressDetails[recipient].latestVoteExpiryDate > block.timestamp)
			updateOutstandingVotes(recipient, amount, TransactionDirection.In);

		updateHolders(recipient, address(0), amount);
	}
	
	function getBalance(address addr) public view returns(uint) {
		return balanceOf(addr);
	}

	function getCreatorBalance() public view returns(uint) {
		return balanceOf(_creator);
	}

	function getCreator() public view returns(address) {
		return _creator;
	}

	function getAddressDetails(address addr) public view returns(AddressDetails memory) {
		return _addressDetails[addr];
	}

	function getHolders() public view returns(uint) {
		return _holders;
	}

	function getMaxTransactionValue() public view returns(uint256) {
		return _maxTxValue;
	}

	function getMaxWalletBalance() public view returns(uint256) {
		return _maxWalletBalance;
	}

	function getCreatorBurnRate() public view returns(uint256) {
		return _creatorBurnRate;
	}

	function getTotalAmountInLiquidityPools() public view returns(uint256) {
		return _totalAmountInLiquidityPools;
	}

	function getTotalAmountInAccountsWithoutVoteRights() public view returns(uint256) {
		return _totalAmountInAccountsWithoutVoteRight;
	}

	function getBallotFee() public view returns(uint256) {
		return _ballotFee;
	}

	function getBallotEscrow() public view returns(uint256) {
		return _ballotEscrow;
	}

	function getExecWindow() public view returns(uint256) {
		return _BallotExecWindow;
	}

	function getBallotLifespan() public view returns(uint256) {
		return _ballotLifespan;
	}

	function getLastBallotIssueId() public view returns(uint) {
		return _ballotLastIssueId;
	}

	function getBallot(uint issueId) public view returns(Ballot memory) {
		return _ballots[issueId];
	}

	function getVoteForBallot(uint issueId) public view returns(Vote memory) {
		return _addressVotedBallots[_msgSender()][issueId];
	}

	function getBallotTurnoutWealthThreshold() public view returns(uint256) {
		return _ballotTurnoutWealthThreshold;
	}

	function getBallotTurnoutThreshold() public view returns(uint256) {
		return _ballotTurnoutThreshold;
	}

	function getBallotVotesInFavorPercentageThreshold() public view returns(uint256) {
		return _ballotVotesInFavorPercentageThreshold;
	}

	function getBallotWealthInFavorPercentageThreshold() public view returns(uint256) {
		return _ballotWealthInFavorPercentageThreshold;
	}

	function getVotingStatus() public view returns(bool) {
		return _votingEnabled;
	}

	function getMinTimeBetweenTransfers() public view returns(uint) {
		return _minTimeBetweenTransfers;
	}

	function getCurrentCharityCause() public view returns(uint){
		return _currentCharityCause;
	}

	function getCharityCause(uint id) public view returns(CharityCause memory){
		return _charityCauses[id];
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    uint256 immutable private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor (uint256 cap_) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}