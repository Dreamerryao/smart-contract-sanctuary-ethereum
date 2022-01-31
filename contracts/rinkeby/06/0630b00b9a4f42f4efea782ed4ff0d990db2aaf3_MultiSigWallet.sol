/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

pragma solidity ^0.8.6;

//SPDX-License-Identifier: None

interface ERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MultiSigWallet {

    address public _owner;
    mapping(address => uint8) public _owners;

    uint private MIN_SIGNATURES = 2;
    uint private _transactionIdx;

    struct Transaction {
      address from;
      address payable to;
      uint amount;
      uint8 signatureCount;
      bool isActive;
    }

    mapping (uint => Transaction) public _transactions;
    mapping (uint => mapping (address => uint8)) public signatures;
    
    uint[] public pendingTxIds;
    uint public pendingTxCnt;
    uint public totalTxCnt;
    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    modifier validOwner() {
        require(msg.sender == _owner || _owners[msg.sender] == 1);
        _;
    }

    event DepositFunds(address from, uint amount);
    event TransactionCreated(address from, address to, uint amount, uint transactionId);
    event TransactionCompleted(address from, address to, uint amount, uint transactionId);
    event TransactionSigned(address by, uint transactionId);
    event TokenWithdraw(address indexed from, address indexed to, uint256 value);
    event ETHWithdraw(address indexed from, address indexed to, uint256 value);

    constructor() {
        _owner = msg.sender;
    }

    function addOwner(address owner)
        isOwner
        public {
        _owners[owner] = 1;
    }

    function removeOwner(address owner)
        isOwner
        public {
        _owners[owner] = 0;
    }

    receive() external payable {
        emit DepositFunds(msg.sender, msg.value);
    }

    function withdraw(uint amount,address payable to)
        public {
        transferTo(to, amount);
    }

    function transferTo(address payable to, uint amount)
        validOwner
        public {
        require(address(this).balance >= amount);
        uint transactionId = _transactionIdx++;

        
        _transactions[transactionId] = Transaction(msg.sender,to,amount,0,true);
        totalTxCnt++;
        pendingTxCnt++;
        pendingTxIds.push(transactionId);
        emit TransactionCreated(msg.sender, to, amount, transactionId);
    }

    function getPendingTransactions(uint indexId)
      public
      view
      returns (address [] memory, address [] memory, uint [] memory, uint [] memory,uint) {
          uint getPendTxLength = pendingTxIds.length;
          address[] memory fromAddress = new address[](getPendTxLength);
          address[] memory toAddress = new address[](getPendTxLength);
          uint[] memory userAmount = new uint[](getPendTxLength);
          uint[] memory userSignatureCount = new uint[](getPendTxLength);
          uint i;
          for(i = 0; i < getPendTxLength; i++){
                fromAddress[i] = _transactions[i].from;
                toAddress[i] = _transactions[i].to;
                userAmount[i] = _transactions[i].amount;
                userSignatureCount[i] = _transactions[i].signatureCount;
          }
        return (fromAddress, toAddress, userAmount, userSignatureCount,indexId);
    }
    
   
    function signTransaction(uint transactionId)
      validOwner
      public {

      Transaction storage transaction = _transactions[transactionId];

      // Transaction must exist
      require(address(0x0) != transaction.from);
      // Creator cannot sign the transaction
      require(msg.sender != transaction.from);
      // Cannot sign a transaction more than once
      require(signatures[transactionId][msg.sender] != 1);

      signatures[transactionId][msg.sender] = 1;
      transaction.signatureCount++;

      emit TransactionSigned(msg.sender, transactionId);

      if (transaction.signatureCount >= MIN_SIGNATURES) {
        require(address(this).balance >= transaction.amount);
        transaction.to.transfer(transaction.amount);
       emit  TransactionCompleted(transaction.from, transaction.to, transaction.amount, transactionId);
        deleteTransaction(transactionId);
      }
    }

    function deleteTransaction(uint transactionId)
      validOwner
      public {
     _transactions[transactionId].isActive = false;
     reestPendingTx(transactionId);
     pendingTxCnt--;
    }

    
   function reestPendingTx(uint removetxId) internal {
       uint[] memory collect = pendingTxIds;
       delete pendingTxIds;
       for(uint i=0; i < collect.length;i++){
            if(collect[i] != removetxId){
                pendingTxIds.push(collect[i]);
            }
       }
   }


    function walletBalance()
      public 
      view
      returns (uint) {
      return address(this).balance;
    }
    
    // Update MIN_SIGNATURES count
    function updateMinSigCount(uint count_) validOwner public {
        MIN_SIGNATURES = count_;
    }
    
    // Show MIN_SIGNATURES count
    function showMinSigCount() public view returns (uint) {
        return MIN_SIGNATURES;
    }
    
    // Withdraw tokens 
    function withdrawToken(address tokenAddr, address to, uint amount, uint transactionId) validOwner public {
      ERC20 token = ERC20(tokenAddr);
        
      Transaction storage transaction = _transactions[transactionId];
      require(to != address(0), "Transfer to zero address");
      // Transaction must exist
      require(address(0x0) != transaction.from);
      // Creator cannot sign the transaction
      require(msg.sender != transaction.from);
      // Cannot sign a transaction more than once
      require(signatures[transactionId][msg.sender] != 1);

      signatures[transactionId][msg.sender] = 1;
      transaction.signatureCount++;

      emit TransactionSigned(msg.sender, transactionId);

      if (transaction.signatureCount >= MIN_SIGNATURES) {
        require(address(this).balance >= transaction.amount);
        transaction.to.transfer(transaction.amount);
        token.transfer(to, amount);
        emit  TransactionCompleted(transaction.from, transaction.to, transaction.amount, transactionId);
        emit TokenWithdraw(address(this), to, amount);
        deleteTransaction(transactionId);
      }
    }
    
    // Withdraw ETH 
    function withdrawETH(address payable to, uint amount, uint transactionId) validOwner public {
        
      Transaction storage transaction = _transactions[transactionId];
      require(to != address(0), "Transfer to zero address");
      // Transaction must exist
      require(address(0x0) != transaction.from);
      // Creator cannot sign the transaction
      require(msg.sender != transaction.from);
      // Cannot sign a transaction more than once
      require(signatures[transactionId][msg.sender] != 1);

      signatures[transactionId][msg.sender] = 1;
      transaction.signatureCount++;

      emit TransactionSigned(msg.sender, transactionId);

      if (transaction.signatureCount >= MIN_SIGNATURES) {
        require(address(this).balance >= transaction.amount);
        transaction.to.transfer(transaction.amount);
        to.transfer(amount);
        emit  TransactionCompleted(transaction.from, transaction.to, transaction.amount, transactionId);
        emit ETHWithdraw(address(this), to, amount);
        deleteTransaction(transactionId);
      }
    }
}