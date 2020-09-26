// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";


//-------------------------------------------------------------------------------------------
// Hujo Localized - A helper contract that facilate the localization part of Hujo  
//-------------------------------------------------------------------------------------------
//TODO Test if its necessary to declare ERC20 again here 
contract HujoLocalized is Ownable {
	
	
	int8 private _maxDistancePoint;
	
	
	mapping(address => int8) private _roundedLongs;
    mapping(address => int8) private _roundedLats;
    
    
    constructor() internal {
    	_maxDistancePoint = 4; //~100km radius
	}
    
    
	function _enrollLocalized(int8 roundedLong, int8 roundedLat) internal {
		require(roundedLong > 0, "Invalid Longitude");
    	require(roundedLat > 0, "Invalid Latitude");
    	
		_roundedLongs[msg.sender] = roundedLong;
    	_roundedLats[msg.sender] = roundedLat;
	}
	
	
	function _withdrawEnrollLocalized() internal {
		_roundedLongs[msg.sender] = 0;
    	_roundedLats[msg.sender] = 0;
	}
	
	
	function _beforeTokenTransferLocalized(address from, address to) internal view { 
		require(from != address(0), "Transfer from the zero address");
		require(_roundedLongs[msg.sender] != 0, "Sender not registered");
    	require(_roundedLongs[to] != 0, "Receiver not registered");
    	//Taken from https://stackoverflow.com/questions/6548940/sql-distance-query-without-trigonometry
    	require(
			(
				(_roundedLats[msg.sender] - _roundedLats[to]) * 
				(_roundedLats[msg.sender] - _roundedLats[to]) + 
				((_roundedLongs[msg.sender] - _roundedLongs[to]) * 2) * 
				((_roundedLongs[msg.sender] - _roundedLongs[to]) * 2)
			) < _maxDistancePoint,
			"Too far apart"
		);
	}
	
	
	// ------------------------------------------------------------------------
    // Policy Adjustments
    // ------------------------------------------------------------------------
	function setMaxDistancePoint(int8 distancePoint) onlyOwner external returns (bool success) {
    	_maxDistancePoint = distancePoint;
    	return true;
    }
	// ------------------------------------------------------------------------
	
	
	// ------------------------------------------------------------------------
    // Contract Info functions
    // ------------------------------------------------------------------------
	function getMaxDistancePoint() external view returns (int8 maxDistancePoint) {
    	return _maxDistancePoint;
    }
	// ------------------------------------------------------------------------
}