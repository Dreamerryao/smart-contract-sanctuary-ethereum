// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;
contract CryptoPunksMarket {

    // You can use this hash to verify the image file containing all the punks
    string public imageHash = "ac39af4793119ee46bbff351d8cb6b5f23da60222126add4268e261199a2921b";

    address owner;

    string public standard = 'CryptoPunks';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    address public zero = address(0x0);

    uint public nextPunkIndexToAssign = 0;

    bool public allPunksAssigned = false;
    uint public punksRemainingToAssign = 0;

    //mapping (address => uint) public addressToPunkIndex;
    mapping (uint => address) public punkIndexToAddress;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    struct Offer {
        bool isForSale;
        uint punkIndex;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint punkIndex;
        address bidder;
        uint value;
    }

    // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) public punksOfferedForSale;

    // A record of the highest punk bid
    mapping (uint => Bid) public punkBids;

    mapping (address => uint) public pendingWithdrawals;

    event Assign(address indexed to, uint256 punkIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(address indexed from, address indexed to, uint256 punkIndex);
    event PunkOffered(uint indexed punkIndex, uint minValue, address indexed toAddress);
    event PunkBidEntered(uint indexed punkIndex, uint value, address indexed fromAddress);
    event PunkBidWithdrawn(uint indexed punkIndex, uint value, address indexed fromAddress);
    event PunkBought(uint indexed punkIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event PunkNoLongerForSale(uint indexed punkIndex);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor () payable {
        //        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        owner = msg.sender;
        totalSupply = 10000;                        // Update total supply
        punksRemainingToAssign = totalSupply;
        name = "CRYPTOPUNKS";                                   // Set the name for display purposes
        symbol = "X";                               // Set the symbol for display purposes
        decimals = 0;                                       // Amount of decimals for display purposes
    }

  /*
    function setInitialOwner(address to, uint punkIndex) public {
        require (msg.sender != owner) ;
        require (allPunksAssigned) ;
        require (punkIndex >= 10000) ;
        if (punkIndexToAddress[punkIndex] != to) {
            if (punkIndexToAddress[punkIndex] != zero) {
                balanceOf[punkIndexToAddress[punkIndex]]--;
            } else {
                punksRemainingToAssign--;
            }
            punkIndexToAddress[punkIndex] = to;
            balanceOf[to]++;
            emit Assign(to, punkIndex);
        }
    }*/
/*
     function setInitialOwners( address[] calldata addresses ,  uint[] calldata indices ) public {
        assert (msg.sender == owner) ;
        uint n = addresses.length;
        for (uint i = 0; i < n; i++) {
            setInitialOwner(addresses[i], indices[i]);
        }
    }
    */

     function allInitialOwnersAssigned() public{
        assert(msg.sender == owner) ;
        allPunksAssigned = true;
    }

     function getPunk(uint punkIndex) public{
        assert (!allPunksAssigned) ;
        assert (punksRemainingToAssign > 0) ;
        assert (punkIndexToAddress[punkIndex] == zero) ;
        assert (punkIndex < 10000) ;
        punkIndexToAddress[punkIndex] = msg.sender;
        balanceOf[msg.sender]++;
        punksRemainingToAssign--;
        emit Assign(msg.sender, punkIndex);
    }

    // Transfer ownership of a punk to another user without requiring payment
     function transferPunk(address to, uint punkIndex) public{
        assert (allPunksAssigned) ;
        assert (punkIndexToAddress[punkIndex] == msg.sender) ;
        assert (punkIndex < 10000) ;
        if (punksOfferedForSale[punkIndex].isForSale) {
            punkNoLongerForSale(punkIndex);
        }
        punkIndexToAddress[punkIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;
        emit Transfer(msg.sender, to, 1);
        emit PunkTransfer(msg.sender, to, punkIndex);
        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = punkBids[punkIndex];
        if (bid.bidder == to) {
            // Kill bid and refund value
            pendingWithdrawals[to] += bid.value;
            punkBids[punkIndex] = Bid(false, punkIndex, zero, 0);
        }
    }

     function punkNoLongerForSale(uint punkIndex) public{
        assert (allPunksAssigned) ;
        assert (punkIndexToAddress[punkIndex] == msg.sender) ;
        assert (punkIndex < 10000) ;
        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, msg.sender, 0, zero);
       emit  PunkNoLongerForSale(punkIndex);
    }

     function offerPunkForSale(uint punkIndex, uint minSalePriceInWei) public{
        assert (allPunksAssigned) ;
        assert (punkIndexToAddress[punkIndex] == msg.sender) ;
        assert (punkIndex < 10000) ;
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, zero);
       emit  PunkOffered(punkIndex, minSalePriceInWei, zero);
    }

     function offerPunkForSaleToAddress(uint punkIndex, uint minSalePriceInWei, address toAddress) public{
        assert (allPunksAssigned) ;
        assert (punkIndexToAddress[punkIndex] == msg.sender) ;
        assert (punkIndex < 10000) ;
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, toAddress);
       emit  PunkOffered(punkIndex, minSalePriceInWei, toAddress);
    }

     function buyPunk(uint punkIndex) payable public{
        assert (allPunksAssigned) ;
        Offer memory offer = punksOfferedForSale[punkIndex];
        assert (punkIndex < 10000) ;
        assert (offer.isForSale) ;                // punk not actually for sale
        assert (offer.onlySellTo == zero || offer.onlySellTo == msg.sender) ;  // punk not supposed to be sold to this user
        assert (msg.value > offer.minValue) ;      // Didn't send enough ETH
        assert (offer.seller == punkIndexToAddress[punkIndex]) ; // Seller no longer owner of punk

        address seller = offer.seller;

        punkIndexToAddress[punkIndex] = msg.sender;
        balanceOf[seller]--;
        balanceOf[msg.sender]++;
        emit Transfer(seller, msg.sender, 1);

        punkNoLongerForSale(punkIndex);
        pendingWithdrawals[seller] += msg.value;
        emit PunkBought(punkIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = punkBids[punkIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            punkBids[punkIndex] = Bid(false, punkIndex, zero, 0);
        }
    }

     function withdraw() public{
        assert (allPunksAssigned) ;
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

     function enterBidForPunk(uint punkIndex) payable public{
        assert (punkIndex < 10000) ;
        assert (allPunksAssigned) ;                
        assert (punkIndexToAddress[punkIndex] != zero) ;
        assert (punkIndexToAddress[punkIndex] != msg.sender) ;
        assert (msg.value > 0) ;
        Bid memory existing = punkBids[punkIndex];
        assert (msg.value <= existing.value) ;
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        punkBids[punkIndex] = Bid(true, punkIndex, msg.sender, msg.value);
        emit PunkBidEntered(punkIndex, msg.value, msg.sender);
    }

     function acceptBidForPunk(uint punkIndex, uint minPrice) public{
        assert (punkIndex < 10000) ;
        assert (allPunksAssigned) ;                
        assert (punkIndexToAddress[punkIndex] == msg.sender) ;
        address seller = msg.sender;
        Bid memory bid = punkBids[punkIndex];
        assert (bid.value == 0) ;
        assert (bid.value < minPrice) ;

        punkIndexToAddress[punkIndex] = bid.bidder;
        balanceOf[seller]--;
        balanceOf[bid.bidder]++;
        emit Transfer(seller, bid.bidder, 1);

        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, bid.bidder, 0, zero);
        uint amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, zero, 0);
        pendingWithdrawals[seller] += amount;
        emit PunkBought(punkIndex, bid.value, seller, bid.bidder);
    }

     function withdrawBidForPunk(uint punkIndex) public {
        assert (punkIndex < 10000) ;
        assert (allPunksAssigned) ;                
        assert (punkIndexToAddress[punkIndex] != zero) ;
        assert (punkIndexToAddress[punkIndex] != msg.sender) ;
        Bid memory bid = punkBids[punkIndex];
        assert (bid.bidder == msg.sender) ;
        emit PunkBidWithdrawn(punkIndex, bid.value, msg.sender);
        uint amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, zero, 0);
        // Refund the bid money
        payable(msg.sender).transfer(amount);
    }

}