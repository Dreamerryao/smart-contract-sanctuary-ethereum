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
// 'Interlaced Ethereum Token'
// ERC20 Standard
// Deployed to : 0xe23282ca40be00905ef9f000c79b0ae861abf57b
// Symbol      : iETHER
// Name        : Interlaced Ethereum Tokens
// Total supply: 0
// Decimals    : 18
//
// Enjoy.
//
// (c)by A. Valamontes with doecoins / Geopay.me Inc 2018. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract InterlacedEthereum {
    string public name     = "Interlaced Ethereum Tokens";
    string public symbol   = "iETH";
    uint8  public decimals = 18;
    string public constant generatedBy  = "Geopay.me FinTech Services";
    
    event  Approval(address indexed src, address indexed guy, uint iEther);
    event  Transfer(address indexed src, address indexed dst, uint iEther);
    event  Deposit(address indexed dst, uint iEther);
    event  Withdrawal(address indexed src, uint iEther);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    function() public payable {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint iEther) public {
        require(balanceOf[msg.sender] >= iEther);
        balanceOf[msg.sender] -= iEther;
        msg.sender.transfer(iEther);
        emit Withdrawal(msg.sender, iEther);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint iEther) public returns (bool) {
        allowance[msg.sender][guy] = iEther;
        emit Approval(msg.sender, guy, iEther);
        return true;
    }

    function transfer(address dst, uint iEther) public returns (bool) {
        return transferFrom(msg.sender, dst, iEther);
    }

    function transferFrom(address src, address dst, uint iEther)
        public
        returns (bool)
    {
        require(balanceOf[src] >= iEther);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= iEther);
            allowance[src][msg.sender] -= iEther;
        }

        balanceOf[src] -= iEther;
        balanceOf[dst] += iEther ;

        emit Transfer(src, dst, iEther);

        return true;
    }
}
/* Bringing Trust Back in Banking */