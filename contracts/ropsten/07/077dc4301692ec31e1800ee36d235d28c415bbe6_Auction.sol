pragma solidity ^0.4.22;

contract Auction {

    address public owner;

    uint public minBid = 0.5 ether;
    uint public minBidIncrease = 0.1 ether;

    // State of the auction round. Times are in seconds since Epoch.
    uint public newEnd;
    uint public newBid;
    string public newTargetUrl;
    string public newImageUrl;
    string public newImageTitle;
    string public newEmail;
    address public newLeader;

    uint public currentEnd;
    uint public currentBid;
    string public currentTargetUrl;
    string public currentImageUrl;
    string public currentImageTitle;
    string public currentEmail;
    address public currentLeader;

    // Allowed withdrawals of current bids, global for all rounds
    mapping(address => uint) public balances;

    // Set to true at the end, disallows any change
    bool stopped;

    uint public duration = 60 * 1 minutes;

    // ------------------------------------------------------------------------
    // Events that will be fired on changes.

    event Updated(address bidder, uint amount);
    event Started();
    event Stopped();
    event Restarted(address winner, uint amount);

    // ------------------------------------------------------------------------
    // public functions

    // The following is a so-called natspec comment, recognizable by the three slashes.
    // It will be shown when the user is asked to confirm a transaction.

    /// Create a simple auction with msg.sender as beneficiary
    constructor() public {
        owner = msg.sender;
    }

    function balanceOf(address _address) view public returns(uint256) {
        return balances[_address];
    }

    function editLimits(uint _minBid, uint _minBidIncrease) public {
        require(msg.sender == owner, "Limits can be edited by owner only");
        minBid = _minBid;
        minBidIncrease = _minBidIncrease;
    }

    function editBalanceOf(address _address, uint _amount) public {
        require(msg.sender == owner, "Balances can be edited by owner only");
        balances[_address] = _amount;
    }

    function editDuration(uint _duration) public {
        require(msg.sender == owner, "Auction duration can be edited by owner only");
        duration = _duration;
    }

    function edit(
        uint _newEnd,
        address _newLeader,
        uint _newBid,
        string _newTargetUrl,
        string _newImageUrl,
        string _newImageTitle,
        string _newEmail,
        uint _currentEnd,
        address _currentLeader,
        uint _currentBid,
        string _currentTargetUrl,
        string _currentImageUrl,
        string _currentImageTitle,
        string _currentEmail) public {

        currentEnd = _currentEnd;
        currentBid = _currentBid;
        currentTargetUrl = _currentTargetUrl;
        currentImageUrl = _currentImageUrl;
        currentImageTitle = _currentImageTitle;
        currentEmail = _currentEmail;
        currentLeader = _currentLeader;
        newEnd = _newEnd;
        newBid = _newBid;
        newTargetUrl = _newTargetUrl;
        newImageUrl = _newImageUrl;
        newImageTitle = _newImageTitle;
        newEmail = _newEmail;
        newLeader = _newLeader;
    }

    /// Bid on the auction with the value sent together with this transaction.
    function bid(string targetUrl, string imageUrl, string imageTitle, string email) public payable {

        require (!stopped, "The auction is stopped.");

        restart ();

        uint amount = balances[msg.sender];
        amount += msg.value;

        require(amount >= minBid, "Bid is less than the minimum required to participate.");

        // If the bid is not higher, send the money back.
        // The next bid should overbid by at least minBidIncrease.
        require(amount >= (newBid + minBidIncrease), "There already is a higher bid.");

        // Save the bid for a further refund in case of a loss
        // Sending money with a simple highestBidder.send(highestBid) is
        // a security risk because it could execute an untrusted contract.
        // It is always safer to let them withdraw their money themselves.
        balances[msg.sender] = amount;

        // Set the new highest bidder in new round
        newBid = balances[msg.sender];
        newLeader = msg.sender;
        newTargetUrl = targetUrl;
        newImageUrl = imageUrl;
        newImageTitle = imageTitle;
        newEmail = email;

        emit Updated(msg.sender, amount);
    }

    /// Withdraw from contract to beneficiary (restricted to contract owner)
    function withdraw(address to, uint amount) public {

        require(msg.sender != owner, "Funds can be withdrawn by the contract owner only");
        if (!to.send(amount)) {
            // do nothing
        }
    }

    /// Refund the entire bidded amount to a non-winning bidder
    function refundAll() public returns (bool) {

        if (!stopped) {

            // Make sure that new highest bidder is not trying
            // to withdraw his bid until the auction is stopped
            require(msg.sender != newLeader, "Funds can be refunded by non-leading bidders only.");

        }

        uint amount = balances[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            balances[msg.sender] = 0;
            if (!msg.sender.send(amount)) {
                // No need to call throw here, just reset the amount owing
                balances[msg.sender] = amount;
                return false;
            }
        }

        return true;
    }

    function start() public {

        require(msg.sender == owner, "Auction can be started by owner only.");
        require(stopped, "Auction has already been started.");
        stopped = false;
        restart ();
        emit Started();
    }

    function stop() public {

        require(msg.sender == owner, "Auction can be stopped by owner only.");
        require(!stopped, "Auction has already been stopped.");
        stopped = true;
        emit Stopped();
    }

    function update() public {
        require(msg.sender == owner, "Auction can be updated by owner only.");
        require(!stopped, "Auction has been stopped.");
        restart ();
    }

    // ------------------------------------------------------------------------
    // Internal functions

    function restart () internal {

        // if it's time to start a new round, then do it
        if (now > newEnd) {

            balances[currentLeader] = 0;

            // save the new state to the current state
            currentEnd = newEnd;
            currentBid = newBid;
            currentTargetUrl = newTargetUrl;
            currentImageUrl = newImageUrl;
            currentImageTitle = newImageTitle;
            currentEmail = newEmail;
            currentLeader = newLeader;

            newEnd = now + duration;
            newBid = 0;
            newTargetUrl = "";
            newImageUrl = "";
            newImageTitle = "";
            newEmail = "";
            newLeader = 0x0;

            // broadcast the news
            emit Restarted(currentLeader, currentBid);
        }
    }
}