// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./commerce/HujoExpirable.sol";
import "./commerce/HujoLocalized.sol";


//-------------------------------------------------------------------------------------------
// Hujo Token - A contract that facilate sharing of resources in close proximity but borderless  
//-------------------------------------------------------------------------------------------
contract Hujo is ERC20, Ownable, HujoExpirable, HujoLocalized {
	using Counters for Counters.Counter;
	
	
	bool private _mintable; 
    uint private _maxTokens;
    uint private _initialTokens;
    uint private _requiredStake;
    uint private _enrollmentFee; //Wei
    uint private _penalityDividendPool;
    Counters.Counter private _numAccounts;
    
    
    mapping(address => uint) _stakeBalances;

    
    event MintingDisabled();
    event Minted(address indexed _to, uint _value);
    event Minced(address indexed _from, uint _value);
    event AnnualTaxDeducted(address indexed _to, uint _value);
    event IdleTaxDeducted(address indexed _to, uint _value);
    event Donated(address indexed _from, uint _value);
    event LogDepositReceived(address sender);
    
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public ERC20("Hujo", "HUJO") {
        _mintable = true;
        _maxTokens = 20;
        _initialTokens = 10;
        //Exchange rate referenced Sept 2020
        _requiredStake = 150000000000000000; //Wei ~ 50 usd
        _enrollmentFee = 15000000000000000; //Wei ~ 5 usd
    }
    
    
    // ------------------------------------------------------------------------
    // Interaction functions
    // ------------------------------------------------------------------------
    function enrol(int8 roundedLong, int8 roundedLat) external payable returns (bool success) {
    	//check
    	require(_mintable, "Disabled");
    	require(!address(msg.sender).isContract(), "Cannot be contract");
    	require(_stakeBalances[msg.sender] > 0, "Already Enrolled");
    	require(msg.value > _requiredStake, "Insufficient fund");
    	
    	//effects
    	_enrollLocalized(roundedLong, roundedLat);
    	_stakeBalances[msg.sender] = msg.value - _enrollmentFee;
    	//TODO chk contract balance to see if we need to explctly declare the amount of eth to be stored in contract?
    	_numAccounts.increment();
    	
    	//interactions
    	payable(owner()).transfer(_enrollmentFee);
    	_mint(msg.sender, _initialTokens);
    	
    	return true;
    }
    
    
    function withdrawEnrol() external {
    	_withdrawEnrollLocalized();
    	_performPenalty(_withdrawEnrolExpirable());
    	uint penalty = _penalityDividendPool.div(_numAccounts.current()); //rounded towards zero
    	uint withdrawal = _stakeBalances[msg.sender] - penalty;
		_penalityDividendPool = _penalityDividendPool.sub(penalty);
    	_stakeBalances[msg.sender] = 0;
    	_numAccounts.decrement();

    	//TODO test if zero value in stakes array still included in count
    	msg.sender.transfer(withdrawal);
    }
    
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
    	_beforeTokenTransferLocalized(from, to);
    	_performPenalty(_beforeTokenTransferExpirable());
    }
    
    
    function _performPenalty (uint penalty) internal {
    	if (penalty <= 0) {
			return;
		}
		//TODO test overflow case
		_stakeBalances[msg.sender] = _stakeBalances[msg.sender].sub(penalty); //reverting when -ve
		//TODO ensure when sender don't have all eth to sub from, this won't add the entire eth amount to dividen fund
		_penalityDividendPool = _penalityDividendPool.add(penalty);
    }
    // ------------------------------------------------------------------------
    
    
    // ------------------------------------------------------------------------
    // Contract Info functions
    // ------------------------------------------------------------------------
    function canJoin() external view returns (bool mintable) {
    	return _mintable;
    }
    
    
    function getMaxTokens() external view returns (uint maxTokens) {
    	return _maxTokens;
    }
    
    
    function getInitialTokens() external view returns (uint initialTokens) {
    	return _initialTokens;
    }
    
    
    function getRequiredStake() external view returns (uint requiredStake) {
    	return _requiredStake;
    }
    
    
    function getEnrollmentFee() external view returns (uint enrollmentFee) {
    	return _enrollmentFee;
    }
    // ------------------------------------------------------------------------
    

    // ------------------------------------------------------------------------
    // Policy Adjustments
    // ------------------------------------------------------------------------
    function setMaxToken(uint token) onlyOwner external {
    	_maxTokens = token;
    }
    
    
    function setInitialBalance(uint token) onlyOwner external {
    	_initialTokens = token;
    }
    
    
    function setEnrollmentFee(uint fee) onlyOwner external {
    	_enrollmentFee = fee;
    }
    // ------------------------------------------------------------------------
    
    
    // ------------------------------------------------------------------------
    // Emergency intervention functions
    // ------------------------------------------------------------------------
    function mintAny(address to, uint tokens) onlyOwner public {
        _mint(to, tokens);
    }
    
    
    function burnAny(address from, uint tokens) onlyOwner public {
    	_burn(from, tokens);
    }
    
    
    function toogleMinting() onlyOwner external returns (bool success) {
    	_mintable = !_mintable;
    	return _mintable;
    }
    // ------------------------------------------------------------------------
    
    
    // ------------------------------------------------------------------------
    // Misc functions
    // ------------------------------------------------------------------------
    function donation() external payable {
    	payable(owner()).transfer(msg.value);
    	emit Donated(msg.sender, msg.value);
    }   
    // ------------------------------------------------------------------------
    
    
    // ------------------------------------------------------------------------
    // Fallbacks. 
    // Ref:
    // https://consensys.github.io/smart-contract-best-practices/recommendations/#keep-fallback-functions-simple
    // https://solidity.readthedocs.io/en/v0.6.7/060-breaking-changes.html#semantic-and-syntactic-changes
    // ------------------------------------------------------------------------
    fallback() external { 
    	revert('Function not found'); 
	}
    
    
    receive() external payable { 
    	emit LogDepositReceived(msg.sender); 
	}
    // ------------------------------------------------------------------------
    
}