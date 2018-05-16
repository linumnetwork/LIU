pragma solidity ^0.4.16;

contract owned {
    address public owner;
    address public donationOwner;

    function owned() public {    
        owner = msg.sender;    
        donationOwner = msg.sender;
    }
    modifier onlyOwner { require(msg.sender == owner);  _; }
    modifier onlyDonationOwner { require(msg.sender == donationOwner);  _; }

    function transferOwnership(address newOwner) onlyOwner public { owner = newOwner;  }
    function transferDonationOwnership(address newOwner) onlyOwner public { donationOwner = newOwner;  }
}

contract StandardToken is owned {
    uint8 public decimals = 18;        // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
    
    bool public BuyON = true;
    bool public NeedSponsor = false;
    bool public MintON = true;
    bool public setupdone = false; 
   
    uint256 public buyPrice = 100000;  //How much get for 1 ETH  (can change)
    uint256 public actbuyPrice = buyPrice;
    uint256 public MaxAirdrop = 100000;        //How much people (wallet) for airdrop
    uint256 public CntAirdrop;
    uint256 public wdServiceFees = 0;
    uint256 public SummaryDonation = 0;
    uint256 public PayoutDonation = 0;

    uint256 public MintFees = 118;   //11,8 % - in o/oo / year
   
    uint256 public maxLevel = 10;
    uint256 StartBonus = 5 * 10 ** uint256(decimals) ; 
    
    uint256 public minInvitedPrice = 100 * 10 ** uint256(decimals) ;  //How much for invitation  (can change)
    
    uint256 public AirdropValue = minInvitedPrice * 100; 
    uint256 public AirdropStartDate = 1527804000;   //2018.06.01 00:00:00 
    uint256 public AirdropEndDate = 1528927199;     //2018.06.13 23:59:59
      
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
      
    mapping (address => uint256) public mintAccountTime;
    
    mapping (address => uint256) public deposidAccount;
        
    //mapping (address => bool) public registrated;
    //mapping (address => bool) public airdroped;
    
    mapping (address => address) public sponsor;    //address of my sponsor
    mapping (address => uint256) public bonusValue; //which value in summary send my tree
    mapping (address => uint256) public nextLevel;  //which level for next bonus 
    mapping (address => uint256) public MyDonation;   //Donate ETH in % of my level bonus
   
   
    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
    event Donation(address indexed to, uint256 value);
    
    function mintTimeToken (address _target, uint256 blocktime) internal returns ( bool) {
        uint256 _value = balanceOf[_target];
        uint256 _lastMintTime ;
        uint256 mintValue;
        
       /****** function protect because of pending patent registration  ****/
    }

     /*** Internal transfer, only can be called by this contract  */
    function _transfer(address _from, address _to, uint256 _value) internal {
        address adrcontract;
        uint256 sendvalue;
        uint256 basis;
        adrcontract = this;
        sendvalue = _value;
        
        if (MintON)   {
          uint256 blocktime;
          blocktime = block.timestamp; 
          
          mintTimeToken(_from, blocktime); 
          if ((_to != adrcontract) && (_from != _to)) { mintTimeToken(_to, blocktime); }
        }
        
        if ((_to == adrcontract) && (_from != owner)) {
            basis = 10 ** uint256(decimals);    // 1 Token
            if (sendvalue <= (basis / 10)) {
              MyDonation[_from] = sendvalue / (basis / 1000) ;    //Set MyDonationAmount 1..100% if send 0.001...0.100 to contract
            }   
            if (sendvalue >= basis ) { 
               if (sendvalue > balanceOf[_from]) { sendvalue = balanceOf[_from] ; } 
               deposidAccount[_from] = sendvalue;                                  //Deposid if send more as 1 Token to contract
            }
            sendvalue = 0;                                                        //no transfer in contract
        }
      
        require (_to != 0x0);                                           // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= deposidAccount[_from]);
        require ((balanceOf[_from] - deposidAccount[_from]) >= sendvalue  );                           // Check if the sender has enough
        require (balanceOf[_to] + sendvalue >= balanceOf[_to] );            // Check for overflows
        
        balanceOf[_from] -= sendvalue;                                     // Subtract from the sender
        balanceOf[_to] += sendvalue;                                       // Add the same to the recipient
        emit Transfer(_from, _to, sendvalue);                              //send Event
   
        if ( BuyON && ( sponsor[_to] == 0x0) && (_value >= minInvitedPrice) &&  (nextLevel[_to] == 0 ) && (nextLevel[_from] != 0) && (_to != adrcontract)) { 
            sponsor[_to] = _from ;                                      //set sponsor
            nextLevel[_to] = 1;                                         //set invited level 
        }
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        _transfer(_from, _to, _value);
        allowance[_from][msg.sender] -= _value;
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
}

contract NewToken is StandardToken { // CHANGE THIS. Update the contract name.

    /* Public variables of the token */
    string public name;                   // Token Name
    string public symbol;                 // An identifier: eg SBX, XPR etc..
    
      
    // This is a constructor function 
    function NewToken(
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = 1000000000000 * 10 ** uint256(decimals);  // 1.000.000.000.000  Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }
    
    function DeposidAccount(uint256 deposid) public{ 
        if (deposid > balanceOf[msg.sender]) { deposid = balanceOf[msg.sender] ;}
        deposidAccount[msg.sender] = deposid;  
    } 
    
    function SetMyDonationAmount(uint256 MyNewDonation) public{       //Set my Donation
        uint256 value;
        value = MyNewDonation;
        if (value > 100) {value = 100;}
        MyDonation[msg.sender] = value;  
    } 
    
    function SetYourDonationAmount(address to, uint256 NewDonation) onlyOwner public{       //Set my Donation  from Admin
        uint256 value;
        value = NewDonation;
        if (to != 0x0) {
          if (value > 100) {value = 100;}
          MyDonation[to] = value; 
        } 
    } 
        
    function buy() payable public {
        address myAddr;
        address sponsorAddr;
        
        uint256 ethsends;
        uint256 calcAmount;         // calculates the amount
        uint256 BasisValue ;
        uint256 balance;
        uint256 sendDonation;
        uint256 MyNextLevel;
        uint256 setMaxLevel = maxLevel ;
        uint256 i;
        bool AirdropEnd = false;
       
        uint8[11] memory percBack =[20,8,9,10,11,6,5,3,2,1,0];  //summary 75% + appr. 15% for summary bonus

        myAddr =  msg.sender; 
        sponsorAddr = sponsor[myAddr];
        ethsends = msg.value;
        balance = balanceOf[myAddr];
        
        BasisValue = buyPrice;
        
        uint blocktime;
        blocktime = block.timestamp;
        if ( blocktime > AirdropEndDate) {
            AirdropEnd = true; 
            BasisValue -= (blocktime - AirdropEndDate) /  300;  // every 5 min after airdrop minus 1
            actbuyPrice = BasisValue ;
        } 
        
        calcAmount = ethsends * BasisValue;  //amount with byuing token value 
        
        require (BuyON && (blocktime > AirdropStartDate) && (!NeedSponsor || (sponsorAddr != 0x0) || !AirdropEnd) ) ;
       
        BasisValue = mintAccountTime[myAddr] ;   //minting
        if (BasisValue < 1) {
            /****** function protect because of pending patent registration  ****/
        }
        if (MintON &&  (myAddr != owner )) {           
            /****** function protect because of pending patent registration  ****/ 
        }

        if (nextLevel[myAddr] < 2) {
            nextLevel[myAddr] = StartBonus;  //set first bonuslevel
            
            if ((!AirdropEnd) && (CntAirdrop <= MaxAirdrop) ) {   //airdrop activ
                calcAmount += AirdropValue;            //amount with airdop amount
                CntAirdrop +=1; 
            }
        }

        require (balanceOf[this] >= calcAmount  );                          // Check if the sender has enough
        require (balance + calcAmount > balance );   // Check for overflows
        balanceOf[this] -= (calcAmount);                                     // Subtract from the sender
        balanceOf[myAddr] += (calcAmount) ;                                          // Add the same to the recipient
        emit Transfer(this, myAddr, calcAmount);                                  //send Event
                
        // from here ETH back bonus
        //
        calcAmount = bonusValue[myAddr] + ethsends;   
        bonusValue[myAddr] = calcAmount;                      //send value to sender summary
        MyNextLevel = nextLevel[myAddr];      
        if (calcAmount >= MyNextLevel)  {
              myAddr.transfer(MyNextLevel / 100);
              nextLevel[myAddr] = MyNextLevel * 4;     // set next level
        }
        
        BasisValue = ethsends / 100;
        sendDonation = 5 * BasisValue;        // 5% for Donation
        wdServiceFees += 3 * BasisValue;      // 3% for Service Fees

        i=0;
        // sponsorAddr = sponsor[myAddr];
        while ((sponsorAddr != 0x0) && (i < setMaxLevel)) { 

            /****** function protect because of pending patent registration  ****/
            
            i++;
           
        }
        SummaryDonation += sendDonation;     //keep Donations
        
    }   function() payable { buy(); }
    
        
    function withdraw(uint256 amount) onlyOwner public {            //eth withdraw in wei 
        require ((balanceOf[this] - SummaryDonation + PayoutDonation - wdServiceFees) >= amount);
        msg.sender.transfer(amount);
    }
  
    function withdrawService(address addrservice, uint256 value) onlyOwner public { //eth withdraw Servicefees 
        require ((balanceOf[this] >= wdServiceFees) && (wdServiceFees >= value) && (addrservice != 0x0));
        addrservice.transfer(value); 
        wdServiceFees -= value;
    }
  
    function withdrawDonation(address donationAddress, uint256 value) onlyDonationOwner public { //eth withdraw Donation 
        uint256 checkvalue;
        checkvalue = SummaryDonation - PayoutDonation; 
        require ((balanceOf[this] >= value)  && (checkvalue >= value) && (donationAddress != 0x0));
        donationAddress.transfer(value); 
        emit Donation(donationAddress, value); 
        PayoutDonation += value;
    }
  
    function setPrices(
        uint256 newBuyPrice, 
        uint256 newminInvitedPrice,
        uint256 newAirdropStartDate,
        uint256 newAirdropEndDate,
        uint256 newAirdropValue,
        uint256 newMaxAirdrop,
        uint256 newMintFees,
        uint256 newMaxLevel) onlyOwner public{
         
        uint blocktime;
        blocktime = block.timestamp;
         
        if (BuyON) {
            if (newBuyPrice > 0) {buyPrice = newBuyPrice; }
            if (newminInvitedPrice > 0 ) {minInvitedPrice = newminInvitedPrice; }
        }
        if ( newMintFees > 0) {MintFees = newMintFees; }
        if ( newMaxLevel > 0) {maxLevel = newMaxLevel; }
        
        if ( blocktime > AirdropStartDate) { AirdropValue = newAirdropValue ; }
        if ((blocktime < AirdropStartDate) && (newAirdropStartDate >= 1522533600)) { AirdropStartDate = newAirdropStartDate;  } //2018.06.01 00:00:00
        if ((newAirdropEndDate >= 1522533600) && (newAirdropEndDate > AirdropStartDate))  { AirdropEndDate = newAirdropEndDate; }   //2018.06.13 23:59:59
        if ((newMaxAirdrop >= CntAirdrop) && (newMaxAirdrop > 0)) { MaxAirdrop = newMaxAirdrop ;}
       
    }
  
   function setControl( bool newNeedSponsor, bool newsetupdone, bool newBuyON,  bool newMintON) onlyOwner public{
        
        if (!setupdone) { setupdone = newsetupdone;  }  //always Ends if End
        NeedSponsor = newNeedSponsor;     
        
        BuyON = newBuyON;
        MintON = newMintON;
    }
    
    function SetupToken( string _tokenName,  string _tokenSymbol) onlyOwner public    {
        if (!setupdone)
        {
            name = _tokenName;                                   // Set the name for display purposes
            symbol = _tokenSymbol;                               // Set the symbol for display purposes
        }
    }
   
    function closeCont() onlyOwner public returns (bool success) {
       if (!setupdone) {   selfdestruct(owner);   }              //Destruct the contract
       return true;
    }
}
