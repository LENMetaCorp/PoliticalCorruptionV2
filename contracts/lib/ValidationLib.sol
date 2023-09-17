// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library ValidationLib {

    // Validation for zero address
    function requireNonZeroAddress(address _address) internal pure {
        require(_address != address(0), "Zero address");
    }

    // Validation for quantity greater than zero
    function requirePositiveQuantity(uint256 _quantity) internal pure {
        require(_quantity > 0, "Quantity must be greater than zero");
    }

    // Validation for series existence
    function requireSeriesExistence(string memory _seriesName, uint256 _seriesLength) internal pure {
        require(_seriesLength > 0, "Series does not exist");
    }

    // Validation for max supply
    function requireMaxSupply(uint256 _minted, uint256 _maxSupply) internal pure {
        require(_minted <= _maxSupply, "Max supply reached");
    }

    // Validation for correct ETH amount
    function requireCorrectEthAmount(uint256 _msgValue, uint256 _totalCost) internal pure {
        require(_msgValue == _totalCost, "Incorrect ETH amount");
    }
}