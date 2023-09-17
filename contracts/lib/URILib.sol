// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library URILib {

    // Function to dynamically construct the URI
    function constructURI(string memory _baseUri, string memory _name, uint256 _number) internal pure returns (string memory) {
        return string(abi.encodePacked(_baseUri, "/", _name, "/", uint2str(_number)));
    }

    // Helper function for uint to string conversion
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (_i != 0) {
            bstr[--k] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}