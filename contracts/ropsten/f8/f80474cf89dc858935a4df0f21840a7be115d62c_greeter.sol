pragma solidity ^0.4.18;
// ----------------------------------------------------------------------------
// 'HelloWorld' contract
//
// Deployed to : 0x91ef4140646d39ee957586cb89dbf70739ca19a5

contract mortal {
    /* Define variable owner of the type address*/
    address owner;

    /* this function is executed at initialization and sets the owner of the contract */

    function mortal() { owner = msg.sender; }
    /* Function to recover the funds on the contract */
    function kill() { if (msg.sender == owner) selfdestruct(owner); }
}

contract greeter is mortal {
    /* define variable greeting of the type string */
    string greeting;
    /* this runs when the contract is executed */
    function greeter(string _greeting) public {
        greeting = _greeting;
    }

    /* main function */
    function greet() constant returns (string) {
        return greeting;
    }

    function setGreeting(string newGreeting) public {
        greeting = newGreeting;
    }

}