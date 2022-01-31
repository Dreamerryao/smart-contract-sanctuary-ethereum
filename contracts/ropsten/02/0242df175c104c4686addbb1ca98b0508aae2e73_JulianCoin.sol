pragma solidity ^0.4.8;

contract ERC20Events {
event Error(string error);

event Approval(address indexed src, address indexed guy, uint wad);
event Transfer(address indexed src, address indexed dst, uint wad);
}

contract JulianCoin is ERC20Events {
uint256 constant JULIAN_COIN = 10**18;
uint256 constant OWNER_ELIGIBLE = 300 * JULIAN_COIN;

string public name = "Julian Coin"; //fancy name: eg Simon Bucks
uint8 public decimals = 18; // How many decimals to show.
string public symbol = "JUL";
bool isPoop;
address constant JULIAN_COIN_TESTNET_MULTISIG =
0xfdd0f30c870e3d69d3fb2287274d9c8def37c15c;
mapping (address => uint256) balances;
mapping (address => bool) admins;

constructor() public {
balances[tx.origin] = OWNER_ELIGIBLE;
admins[tx.origin] = true;
isPoop = false;
}
function totalSupply() public view returns (uint) {
return 1000000000000;
}

function getIsPoop() public view returns (bool) {
return isPoop;
}

function setIsPoop(bool newIsPoop) public {
// require(JULIAN_COIN_TESTNET_MULTISIG == tx.origin);
isPoop = newIsPoop;
}

// function addAdmin(address admin) public {
// if ()
// admins[ad]
// }
function balanceOf(address guy) public constant returns (uint) {
return balances[guy];
}

function isAdmin(address user) public constant returns (bool) {
return admins[user];
}

function setWalletAmount(address guy, uint256 amount) public returns (uint) {
require(admins[tx.origin]);
balances[guy] = amount;
return amount;
}

function approve(address guy, uint wad) public returns (bool) {
return balances[guy] > wad;
}

function transfer(address dst, uint wad) public returns (bool) {
require(balances[tx.origin] >= wad);
balances[tx.origin] -= wad;
balances[dst] += wad;

return true;
}

// function transferFrom(
// address src, address dst, uint wad
// ) public returns (bool);
}