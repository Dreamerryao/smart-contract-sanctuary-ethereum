/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT

// File: evaluaciones-universitarias/SafeMath.sol


pragma solidity 0.7.0;

// Implementacion de la libreria SafeMath para realizar las operaciones de manera segura
// Fuente: "https://gist.github.com/giladHaimov/8e81dbde10c9aeff69a1d683ed6870be"

library SafeMath{
    // Restas
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    // Sumas
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
    
    // Multiplicacion
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
}

// File: evaluaciones-universitarias/auxTests.sol


pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;


//Interface de nuestro token ERC20
interface IERC20{
    //Devuelve la cantidad de tokens en existencia
    function totalSupply() external view returns (uint256);

    //Devuelve la cantidad de rokens para una dirección indicada por parámetro
    function balanceOf(address account) external view returns (uint256);

    //Devuelve el número de token que el spender podrá gastar en nombre del propietario (owner)
    function allowance(address owner, address spender) external view returns (uint256);

    //Devuelve un valor booleano resultado de la operación indicada
    function transfer(address recipient, uint256 amount) external returns (bool);

    //Devuelve un valor booleano con el resultado de la operación de gasto
    function approve(address spender, uint256 amount) external returns (bool);

    //Devuelve un valor booleano con el resultado de la operación de paso de una cantidad de tokens usando el método allowance()
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    //Evento que se debe emitir cuando una cantidad de tokens pase de un origen a un destino
    event Transfer(address indexed from, address indexed to, uint256 value);

    //Evento que se debe emitir cuando se establece una asignación con el mmétodo allowance()
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//Implementación de las funciones del token ERC20
contract ERC20Basic is IERC20{

    string public constant name = "ERC20BlockchainAZ";
    string public constant symbol = "ERC";
    uint8 public constant decimals = 18;

   
    using SafeMath for uint256;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint256 totalSupply_;

    constructor (uint256 initialSupply) {
        totalSupply_ = initialSupply;
        balances[msg.sender] = totalSupply_;
    }


    function totalSupply() public override view returns (uint256){
        return totalSupply_;
    }

    function increaseTotalSupply(uint newTokensAmount) public {
        totalSupply_ += newTokensAmount;
        balances[msg.sender] += newTokensAmount;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256){
        return balances[tokenOwner];
    }

    function allowance(address owner, address delegate) public override view returns (uint256){
        return allowed[owner][delegate];
    }

    function transfer(address recipient, uint256 numTokens) public override returns (bool){
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[recipient] = balances[recipient].add(numTokens);
        emit Transfer(msg.sender, recipient, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool){
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool){
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}