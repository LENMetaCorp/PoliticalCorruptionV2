// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library StatisticsLib {

    // Update minted packs for a series
    function updateMintedPacks(string memory _seriesName, uint256 _mintedPacks, uint256 _quantity) internal pure returns (uint256) {
        return _mintedPacks + _quantity;
    }

    // Update tokens minted by an address
    function updateTokensMintedByAddress(uint256 _tokensMintedByAddress, uint256 _quantity) internal pure returns (uint256) {
        return _tokensMintedByAddress + _quantity;
    }

    // Get minting statistics
    function getMintStats(uint256 _numberMinted, uint256 _currentTotalSupply, uint256 _maxSupply) internal pure returns (uint256, uint256, uint256) {
        return (_numberMinted, _currentTotalSupply, _maxSupply);
    }
}