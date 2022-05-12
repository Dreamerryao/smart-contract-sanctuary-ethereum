pragma solidity 0.4.24;

library SafeMathExt{
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function pow(uint256 a, uint256 b) internal pure returns (uint256) {
    if (b == 0){
      return 1;
    }
    if (b == 1){
      return a;
    }
    uint256 c = a;
    for(uint i = 1; i<b; i++){
      c = mul(c, a);
    }
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function roundUp(uint256 a, uint256 b) public pure returns(uint256){
    // ((a + b - 1) / b) * b
    uint256 c = (mul(div(sub(add(a, b), 1), b), b));
    return c;
  }
}