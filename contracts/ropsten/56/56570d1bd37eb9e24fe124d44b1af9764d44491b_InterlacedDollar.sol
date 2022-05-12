/* 
 * 
 *                                                                           
 *                      ;'+:                                                                         
 *                       ''''''`                                                                     
 *                        ''''''';                                                                   
 *                         ''''''''+.                                                                
 *                          +''''''''',                                                              
 *                           '''''''''+'.                                                            
 *                            ''''''''''''                                                           
 *                             '''''''''''''                                                         
 *                             ,'''''''''''''.                                                       
 *                              '''''''''''''''                                                      
 *                               '''''''''''''''                                                     
 *                               :'''''''''''''''.                                                   
 *                                '''''''''''''''';                                                  
 *                                .'''''''''''''''''                                                 
 *                                 ''''''''''''''''''                                                
 *                                 ;''''''''''''''''''                                               
 *                                  '''''''''''''''''+'                                              
 *                                  ''''''''''''''''''''                                             
 *                                  '''''''''''''''''''',                                            
 *                                  ,''''''''''''''''''''                                            
 *                                   '''''''''''''''''''''                                           
 *                                   ''''''''''''''''''''':                                          
 *                                   ''''''''''''''''''''+'                                          
 *                                   `''''''''''''''''''''':                                         
 *                                    ''''''''''''''''''''''                                         
 *                                    .''''''''''''''''''''';                                        
 *                                    ''''''''''''''''''''''`                                       
 *                                     ''''''''''''''''''''''                                       
 *                                       ''''''''''''''''''''''                                      
 *                  :                     ''''''''''''''''''''''                                     
 *                  ,:                     ''''''''''''''''''''''                                    
 *                  :::.                    ''+''''''''''''''''''':                                  
 *                  ,:,,:`        .:::::::,. :''''''''''''''''''''''.                                
 *                   ,,,::::,.,::::::::,:::,::,''''''''''''''''''''''';                              
 *                   :::::::,::,::::::::,,,''''''''''''''''''''''''''''''`                           
 *                    :::::::::,::::::::;'''''''''''''''''''''''''''''''''+`                         
 *                    ,:,::::::::::::,;''''''''''''''''''''''''''''''''''''';                        
 *                     :,,:::::::::::'''''''''''''''''''''''''''''''''''''''''                       
 *                      ::::::::::,''''''''''''''''''''''''''''''''''''''''''''                      
 *                       :,,:,:,:''''''''''''''''''''''''''''''''''''''''''''''`                     
 *                        .;::;'''''''''''''''''''''''''''''''''''''''''''''''''                     
 *                            :'+'''''''''''''''''''''''''''''''''''''''''''''''                     
 *                                  ``.::;'''''''''''''';;:::,..`````,'''''''''',                    
 *                                                                       ''''''';                    
 *                                                                         ''''''                    
 *                           .''''''';       '''''''''''''       ''''''''   '''''                    
 *                          '''''''''''`     '''''''''''''     ;'''''''''';  ''';                    
 *                         '''       '''`    ''               ''',      ,'''  '':                    
 *                        '''         :      ''              `''          ''` :'`                    
 *                        ''                 ''              '':          :''  '                     
 *                        ''                 ''''''''''      ''            ''  '                     
 *                       `''     '''''''''   ''''''''''      ''            ''                        
 *                        ''     '''''''':   ''              ''            ''                        
 *                        ''           ''    ''              '''          '''                        
 *                        '''         '''    ''               '''        '''                         
 *                         '''.     .'''     ''                '''.    .'''                         
 *                          `''''''''''      '''''''''''''`    `''''''''''                          
 *                            '''''''        '''''''''''''`      .''''''.                            
 *                                                                                                    
*/
pragma solidity ^0.4.25;
// ----------------------------------------------------------------------------
// 'Interlaced Dollar'
// ERC20 Standard
// Deployed to : 0xe23282ca40be00905ef9f000c79b0ae861abf57b
// Symbol      : iUSD
// Name        : Interlaced Dollar
// Total supply: 0
// Decimals    : 2
//
// Enjoy.
//
// (c)by A. Valamontes with doecoins / Geopay.me Inc 2018. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract InterlacedDollar {
    string public name     = "Interlaced Dollar";
    string public symbol   = "iUSD";
    uint8  public decimals = 18;
    string public constant generatedBy  = "Geopay.me FinTech Services";
    
    event  Approval(address indexed src, address indexed guy, uint iUSD);
    event  Transfer(address indexed src, address indexed dst, uint iUSD);
    event  Deposit(address indexed dst, uint iUSD);
    event  Withdrawal(address indexed src, uint iUSD);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    function() public payable {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint iUSD) public {
        require(balanceOf[msg.sender] >= iUSD);
        balanceOf[msg.sender] -= iUSD;
        msg.sender.transfer(iUSD);
        emit Withdrawal(msg.sender, iUSD);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint iUSD) public returns (bool) {
        allowance[msg.sender][guy] = iUSD;
        emit Approval(msg.sender, guy, iUSD);
        return true;
    }

    function transfer(address dst, uint iUSD) public returns (bool) {
        return transferFrom(msg.sender, dst, iUSD);
    }

    function transferFrom(address src, address dst, uint iUSD)
        public
        returns (bool)
    {
        require(balanceOf[src] >= iUSD);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= iUSD);
            allowance[src][msg.sender] -= iUSD;
        }

        balanceOf[src] -= iUSD;
        balanceOf[dst] += iUSD;

        emit Transfer(src, dst, iUSD);

        return true;
    }
}
/* Bringing Trust Back in Banking */