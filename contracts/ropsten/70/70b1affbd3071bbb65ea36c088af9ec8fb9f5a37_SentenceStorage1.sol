pragma solidity ^0.5.0;

contract SentenceStorage1 {
  uint storedData;

  mapping (uint => DocData) docData;

  struct DocData {
    string ipfsHash;
		address ownerAddress;
	}

  uint indexDocData=0;

  // mapping (address => uint) uints1;
	// mapping (uint => string) ipfsHash;

	// uint[] public uintarray;
	// DeviceData[] public deviceDataArray;
  //   DeviceData public singleDD;

	// struct DeviceData {
	// 	string deviceBrand;
	// 	string deviceYear;
	// 	string batteryWearLevel;
	//}

  function set(uint x) public {
    storedData = x;
  }

  function get() public view returns (uint) {
    return storedData;
  }

  function getDocData(uint x) public view returns (string memory,address) {
    if(x ==indexDocData){
      return (string('none') ,address(0x0));

    }
    return (docData[x].ipfsHash,docData[x].ownerAddress);
  }
  function setDocData(string memory x) public {
    docData[indexDocData] = DocData(x, msg.sender);
    indexDocData=indexDocData+1;

    // _transfer(_ownerAddress,msg.sender,1);
  }
}