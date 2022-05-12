pragma solidity ^0.4.24;
contract ToolChain {

    event logSetAgreement(address indexed borrower, string tool, uint estimatedBorrowDays, uint deposit, uint _startTime);

    event logEndAgreement(address indexed borrower, string tool, uint returnedDeposit, uint fee, uint hoursBorrowed, uint _endTime);     

    event logTransfer(address indexed from, address indexed to, uint256 value);      

    struct BorrowAgreement {
        uint startTime;
        uint estimatedBorrowDays;
        string tool;
        uint deposit;
    }
    
    mapping(address => BorrowAgreement[]) public borrowAgreementsForUser;
    address public masterAddress = 0xD0328FDC2f7ED40a675A4D5e99175A31131FDFEd;

    function setMasterAddress(address _address) public {
        masterAddress = _address;
    }

    function getMasterAdress() public view returns(address) {
        return masterAddress;
    }

    function getFirstBorrowAgreement(address _address) public view returns(uint, uint, string, uint) { 
        BorrowAgreement[] storage agreements = borrowAgreementsForUser[_address]; 
        for (uint i = 0; i < agreements.length ; i++) { 
            BorrowAgreement storage agreement = agreements[i]; 
            if (agreement.startTime > 0) { 
                return (agreement.startTime, agreement.estimatedBorrowDays, agreement.tool, agreement.deposit); 
            }          
        } 
 
        return (0, 0, '0', 0); 
    } 
    
    function setBorrowAgreement(uint _startTime, uint _estimatedBorrowDays, string _tool) public payable {
        BorrowAgreement[] storage agreements = borrowAgreementsForUser[msg.sender];
        BorrowAgreement memory agreement = BorrowAgreement({startTime: _startTime,  estimatedBorrowDays: _estimatedBorrowDays, tool:_tool, deposit: msg.value});
        
        agreements.push(agreement);
        emit logSetAgreement(msg.sender, _tool, _estimatedBorrowDays, msg.value, _startTime);
    }

    function endBorrowAgreement(string _tool, uint _currentTime, uint _hourRate) public payable {
        BorrowAgreement[] storage agreements = borrowAgreementsForUser[msg.sender];
        for (uint i = 0; i < agreements.length ; i++) {
            BorrowAgreement storage agreement = agreements[i];
            if (stringsEqual(agreement.tool, _tool)) {
                uint timeBorrowed = _currentTime - agreement.startTime;
                uint hoursBorrowed = (timeBorrowed / 3600) + 1;
                
                uint fee = hoursBorrowed * _hourRate;              
                uint depositToReturn = agreement.deposit - fee;

                masterAddress.transfer(fee);
                emit logTransfer(address(this), masterAddress, fee);

                msg.sender.transfer(depositToReturn); 
                emit logTransfer(address(this), msg.sender, depositToReturn); 

                delete agreements[i];
                emit logEndAgreement(msg.sender, _tool, depositToReturn, fee, hoursBorrowed, _currentTime);
            }
        }
    }

    function stringsEqual(string storage _a, string memory _b) view internal returns (bool) {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length) {
            return false;
        }

        for (uint i = 0; i < a.length; i ++)
			if (a[i] != b[i]) {
                return false;
            }
        return true;
    }

    function() public payable {  
        emit logTransfer(msg.sender, address(this), msg.value);
    }   
}