/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

// GDT Airdrop
// Author: Ben Gehmlich

pragma solidity ^0.7.1;

interface IGorillaDiamond {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
}

contract AirdropGDT {

    IGorillaDiamond gorillaDiamondInstance = IGorillaDiamond(0x754D73CbB65B0287884E39a510F77805f5D634e1);

    address public owner;                                                  
     
     modifier onlyOwner {               
        require(msg.sender == owner);   
        _;   
    }
    
     constructor(){                     
         owner = msg.sender;  
    } 

    function destroy() public onlyOwner {
        address payable receiver = msg.sender;
        selfdestruct(receiver);
    }

    address[100] accounts;

    /*
    function pushSetToArray(address address1, address address2, address address3, address address4, address address5, address address6, address address7, address address8, address address9, address address10) public onlyOwner returns(bool) {
        accounts.push(address1);
        accounts.push(address2);
        accounts.push(address3);
        accounts.push(address4);
        accounts.push(address5);
        accounts.push(address6);
        accounts.push(address7);
        accounts.push(address8);
        accounts.push(address9);
        accounts.push(address10);
        return true;
    }
    
    
    function pushToArray(address receiver) public onlyOwner returns(bool) {
        accounts.push(receiver);
        return true;
    }
    */

    function setArray1(address address1, address address2, address address3, address address4, address address5, address address6, address address7, address address8, address address9, address address10) public onlyOwner returns(bool) {
        accounts[0] = address1;
        accounts[1] = address2;
        accounts[2] = address3;
        accounts[3] = address4;
        accounts[4] = address5;
        accounts[5] = address6;
        accounts[6] = address7;
        accounts[7] = address8;
        accounts[8] = address9;
        accounts[9] = address10;
        return true;
    }

    function setArray2(address address1, address address2, address address3, address address4, address address5, address address6, address address7, address address8, address address9, address address10) public onlyOwner returns(bool) {
        accounts[10] = address1;
        accounts[11] = address2;
        accounts[12] = address3;
        accounts[13] = address4;
        accounts[14] = address5;
        accounts[15] = address6;
        accounts[16] = address7;
        accounts[17] = address8;
        accounts[18] = address9;
        accounts[19] = address10;
        return true;
    }

    function setArray3(address address1, address address2, address address3, address address4, address address5, address address6, address address7, address address8, address address9, address address10) public onlyOwner returns(bool) {
        accounts[20] = address1;
        accounts[21] = address2;
        accounts[22] = address3;
        accounts[23] = address4;
        accounts[24] = address5;
        accounts[25] = address6;
        accounts[26] = address7;
        accounts[27] = address8;
        accounts[28] = address9;
        accounts[29] = address10;
        return true;
    }

    function setArray4(address address1, address address2, address address3, address address4, address address5, address address6, address address7, address address8, address address9, address address10) public onlyOwner returns(bool) {
        accounts[30] = address1;
        accounts[31] = address2;
        accounts[32] = address3;
        accounts[33] = address4;
        accounts[34] = address5;
        accounts[35] = address6;
        accounts[36] = address7;
        accounts[37] = address8;
        accounts[38] = address9;
        accounts[39] = address10;
        return true;
    }

    function setArray5(address address1, address address2, address address3, address address4, address address5, address address6, address address7, address address8, address address9, address address10) public onlyOwner returns(bool) {
        accounts[40] = address1;
        accounts[41] = address2;
        accounts[42] = address3;
        accounts[43] = address4;
        accounts[44] = address5;
        accounts[45] = address6;
        accounts[46] = address7;
        accounts[47] = address8;
        accounts[48] = address9;
        accounts[49] = address10;
        return true;
    }

    function setArray6(address address1, address address2, address address3, address address4, address address5, address address6, address address7, address address8, address address9, address address10) public onlyOwner returns(bool) {
        accounts[50] = address1;
        accounts[51] = address2;
        accounts[52] = address3;
        accounts[53] = address4;
        accounts[54] = address5;
        accounts[55] = address6;
        accounts[56] = address7;
        accounts[57] = address8;
        accounts[58] = address9;
        accounts[59] = address10;
        return true;
    }

    function setArray7(address address1, address address2, address address3, address address4, address address5, address address6, address address7, address address8, address address9, address address10) public onlyOwner returns(bool) {
        accounts[60] = address1;
        accounts[61] = address2;
        accounts[62] = address3;
        accounts[63] = address4;
        accounts[64] = address5;
        accounts[65] = address6;
        accounts[66] = address7;
        accounts[67] = address8;
        accounts[68] = address9;
        accounts[69] = address10;
        return true;
    }function setArray8(address address1, address address2, address address3, address address4, address address5, address address6, address address7, address address8, address address9, address address10) public onlyOwner returns(bool) {
        accounts[70] = address1;
        accounts[71] = address2;
        accounts[72] = address3;
        accounts[73] = address4;
        accounts[74] = address5;
        accounts[75] = address6;
        accounts[76] = address7;
        accounts[77] = address8;
        accounts[78] = address9;
        accounts[79] = address10;
        return true;
    }function setArray9(address address1, address address2, address address3, address address4, address address5, address address6, address address7, address address8, address address9, address address10) public onlyOwner returns(bool) {
        accounts[80] = address1;
        accounts[81] = address2;
        accounts[82] = address3;
        accounts[83] = address4;
        accounts[84] = address5;
        accounts[85] = address6;
        accounts[86] = address7;
        accounts[87] = address8;
        accounts[88] = address9;
        accounts[89] = address10;
        return true;
    }

    function setArray10(address address1, address address2, address address3, address address4, address address5, address address6, address address7, address address8, address address9, address address10) public onlyOwner returns(bool) {
        accounts[90] = address1;
        accounts[91] = address2;
        accounts[92] = address3;
        accounts[93] = address4;
        accounts[94] = address5;
        accounts[95] = address6;
        accounts[96] = address7;
        accounts[97] = address8;
        accounts[98] = address9;
        accounts[99] = address10;
        return true;
    }

    function getArray() public view onlyOwner returns(address[100] memory) {
        return accounts;
    }


    // Ahmad must approve, in GDT, this contract to transfer in the tokens 
    // or must transfer in the tokens manually before any transfer call - probably easiest
    // contract/caller also needs BNB to use to make the call

    function transferIn() public onlyOwner returns(bool) {
        require(gorillaDiamondInstance.transferFrom(0x8Cf0eb6226C973b042dA1269442ACFeBc67Cc2ca, address(this), 1000000000000000), 'transferFrom failed');
        return true;
    }

    function transferToAll() public onlyOwner returns(bool) {
        for (uint i = 0; i < accounts.length; i++) {
            require(gorillaDiamondInstance.approve(address(this), 1000000000000), 'approve failed');
            require(gorillaDiamondInstance.transfer(accounts[i], 1000000000000), 'transferFrom failed');
        }
        return true;
    }

    // important to receive BNB
    receive() payable external {}

}