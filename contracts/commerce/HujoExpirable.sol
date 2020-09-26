// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


//-------------------------------------------------------------------------------------------
//Hujo Expirable - A helper contract that facilate the expirable part of Hujo  
//-------------------------------------------------------------------------------------------
//TODO Test if its necessary to declare ERC20 again here
contract HujoExpirable is Ownable {
	using SafeMath for uint256;
	
	
	uint private _idleFee;
	
	
	mapping(address => uint) private _lastTransactionDates;
	
	
	constructor() internal {
		_idleFee = 6000000000000000; //Wei ~ 2 usd monthly
	}
	
	
	function _beforeTokenTransferExpirable() internal returns (uint penalty) {
		_lastTransactionDates[msg.sender] = now;
		return _getIdleFee();
	}
	
	
	function _withdrawEnrolExpirable() internal returns (uint penalty) {
		_lastTransactionDates[msg.sender] = 0;
		return _getIdleFee();
	}
	
	
	function _getIdleFee() internal view returns (uint idleFee) {
		uint monthsIdled = (now - _lastTransactionDates[msg.sender]) / 30 days;
		if (monthsIdled > 0) {
			return _idleFee.mul(monthsIdled);
		}
		return 0;
	}
	

	// ------------------------------------------------------------------------
    // Policy Adjustments
    // ------------------------------------------------------------------------
	function setIdleFee(uint fee) onlyOwner external returns (bool success) {
    	_idleFee = fee;
    	return true;
    }
	// ------------------------------------------------------------------------
	
	
	// ------------------------------------------------------------------------
    // Contract Info functions
    // ------------------------------------------------------------------------
	function getIdleFee() external view returns (uint idleFee) {
    	return _idleFee;
    }
	
	
	// ------------------------------------------------------------------------
    // User Info functions
    // ------------------------------------------------------------------------
	function getLastTransactionDate() external view returns (uint lastTransactionDate) {
		return _lastTransactionDates[msg.sender];
	}
	// ------------------------------------------------------------------------
}
