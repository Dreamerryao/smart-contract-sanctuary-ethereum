/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

pragma solidity >=0.8.0 <0.9.0;

// SPDX-License-Identifier: UNLICENSED

contract GameBet {
    
    address[] private playerList;
    address   private owner; // receives commission
    uint256   private entryFee;
    uint16    private bp; // percentage the owner recieves in basis points (385 = 3.85%)
    uint256   private commission; // in wei
    
    event playerJoinedGame(address player);
    event playerLostGame(address player);
    event playerWonGame(address player, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner may call this function.");
        _;
    }
    
    modifier validEntryFee(uint256 _fee) {
        require(_fee >= 10000000000000, "Entry fee cannot be under 1e13 wei.");
        _;
    }
    
    modifier validBP(uint16 _bp) {
        require(_bp <= 9999, "bp must be lower than 100% in basis points.");
        _;
    }

    constructor(uint256 _entryFee, uint16 _bp) validBP(_bp) validEntryFee(_entryFee) {
        owner = msg.sender;
        entryFee = _entryFee;
        bp = _bp;
        commission = getXPercentageOfY(bp, entryFee);
    }
    
    // **********PUBLIC FUNCTIONS**********

    function getOwner() public view returns (address) {
        return owner;
    }
    
    function getEntryFee() public view returns (uint256) {
        return entryFee;
    }
    
    function getPot() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getBP() public view returns (uint16) {
        return bp;
    }
    
    function getCommission() public view returns (uint256) {
        return commission;
    }
    
    function getPlayerIndex(address player) public view returns (uint32) {
        for (uint32 i = 0; i < playerList.length; i++) {
            if (playerList[i] == player) return i;
        }
        revert("Player does not exist.");
    }
    
    function getPlayerAtIndex(uint256 index) public view returns (address) {
        require(index < playerList.length, "Index out of bounds.");
        return playerList[index];
    }
    
    function getPlayerArray() public view returns (address[] memory) {
        return playerList;
    }
    
    function checkPlayerExists(address player) public view returns (bool) {
        for (uint32 i = 0; i < playerList.length; i++) {
            if (playerList[i] == player) return true;
        }
        return false;
    }

    function joinBet() public payable {
        require(!checkPlayerExists(msg.sender), "Player already exists in the list.");
        require(msg.sender != owner, "Owner address may not join the bet.");
        require(msg.value == entryFee, "Wrong value for entry fee.");

        payable(owner).transfer(commission);

        playerList.push(msg.sender);
        emit playerJoinedGame(msg.sender);
    }
    
    // **********INTERNAL FUNCTIONS**********
    
    // Calculate x percent of y rounding down
    // x (percentage in basis points) = a * scale + b
    // y (value to get percentage of) = c * scale + d
    // only use in >=0.8.0 for built in overflow check
    function getXPercentageOfY (uint16 x, uint256 y) internal pure returns (uint256) {
        uint128 scale = 10000;
        uint a = x / scale;
        uint b = x % scale;
        uint c = y / scale;
        uint d = y % scale;
        
        return a * c * scale + a * d + b * c + b * d / scale;
    }
    
    function removePlayer(address player) internal {
        uint32 idx = getPlayerIndex(player);
        require(idx < playerList.length);

        // shift everything on the right of the deleted address once to the left
        // and decrement the array length
        for (uint32 i = idx; i < playerList.length - 1; i++) {
            playerList[i] = playerList[i + 1];
        }
        playerList.pop();
    }
    
    // **********AUTHORIZED FUNCTIONS**********
    
    function setOwner(address newOwner) public onlyOwner {
        require(!checkPlayerExists(newOwner), "A player may not also be an owner.");
        owner = newOwner;
    }
    
    function setBasisPoints(uint16 newBP) public onlyOwner validBP(newBP) {
        bp = newBP;
        commission = getXPercentageOfY(bp, entryFee);
    }
    
    function setEntryFee(uint256 newEntryFee) public onlyOwner validEntryFee(newEntryFee) {
        require(newEntryFee > 0, "New entry fee cannot be 0.");
        entryFee = newEntryFee;
        commission = getXPercentageOfY(bp, entryFee);
    }

    function playerLost(address player) public onlyOwner {
        removePlayer(player);
        emit playerLostGame(player);
    }

    function playerWon(address player, uint256 amount) public onlyOwner {
        require(amount > 3000000, "Minimum payout is 3,000,000 wei.");
        require(amount <= getPot(), "Cannot withdraw more than the pot.");
        
        // A player's score must be transparent, fair, and tamper-proof.
        // It'll update too much for on-chain data, so this'll likely live in the server/Moralis.
        // The SC has no knowledge of the player's score and whether it's a fair payout.
        // It's a point of weakness to be careful of.

        removePlayer(player);
        payable(player).transfer(amount);
        emit playerWonGame(player, amount);
    }
    
    // allow the owner to deposit ether into the betting pot
    function depositIntoPot() public payable onlyOwner {}
    
    function destroy() public onlyOwner {
        selfdestruct(payable(owner));
    }
}