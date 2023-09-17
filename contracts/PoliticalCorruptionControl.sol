// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./PoliticalCorruptionPacksERC721Upgradable.sol";

contract PoliticalCorruptionControl is AccessControl, ReentrancyGuard {
    PoliticanCorruptionPacks private corruptionPacks;

    bytes32 public constant CARD_CREATOR_ROLE = keccak256("CARD_CREATOR_ROLE");
    bytes32 public constant CORRUPTION_PACKS_ROLE = keccak256("CORRUPTION_PACKS_ROLE");

    // Series related data
    struct Series {
        string name;
        string baseUri;
        string uri;
        uint256 maxPacks;
        uint256 mintedPacks;
        uint256 packPrice;
        uint256[] cardIds;
        mapping(string => uint256) dropRates;
    }

    // Politician related data
    struct Politician {
        string series;
        string name;
        uint256 number;
        uint256 ageAtBooking;
        string DOB;
        uint256 weightAtBooking;
        uint256 height;
        string highestHeldPoliticalStation;
        string bookingLocation;
        uint256 bailOrBond;
        string[] charges;
        uint256 rarity;
    }

    mapping(string => Politician[]) public politiciansBySeries;
    mapping(uint256 => Politician) public politicians;
    uint256 private tokenIdCounter;

    // Drop rates for each rarity
    mapping(string => uint256) public defaultDropRates;

    mapping(string => Series) public seriesMapping;
    string[] public seriesList;

    // Private variable to increase randomness
    uint256 private nonce = 0;

    event CorruptionPacksAddressUpdated(address indexed newAddress);
    event SeriesCreated(string indexed seriesName);

    constructor(address _cardCreatorAddress, address _corruptionPacksAddress) {
        corruptionPacks = PoliticanCorruptionPacks(_corruptionPacksAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function getCorruptionPacksAddress() public view returns (address) {
        return address(corruptionPacks);
    }

    function updateCorruptionPacksAddress(address _corruptionPacksAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_corruptionPacksAddress != address(0), "Cannot update to zero address");
        require(_corruptionPacksAddress != address(corruptionPacks), "Cannot update to the same address");

        corruptionPacks = PoliticanCorruptionPacks(_corruptionPacksAddress);
        emit CorruptionPacksAddressUpdated(_corruptionPacksAddress);
    }

    // Function to dynamically construct the URI 
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        Politician memory politician = politicians[tokenId];
        Series memory series = seriesMapping[politician.series];
    
        return URILib.constructURI(series.baseUri, politician.name, politician.number);
    }

    // Helper function for uint to string conversion
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        // Implement uint to string conversion
    }

    function createPolitician(
        string memory _series,
        string memory _name,
        uint256 _number,
        uint256 _ageAtBooking,
        string memory _DOB,
        uint256 _weightAtBooking,
        uint256 _height,
        string memory _highestHeldPoliticalStation,
        string memory _bookingLocation,
        uint256 _bailOrBond,
        string[] memory _charges,
        uint256 _rarity
        string memory _uri
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(seriesMapping[_series].name).length > 0, "Series does not exist");

        Politician memory newPolitician = Politician({
            series: _series,
            name: _name,
            newPolitician.number = _number;
            ageAtBooking: _ageAtBooking,
            DOB: _DOB,
            weightAtBooking: _weightAtBooking,
            height: _height,
            highestHeldPoliticalStation: _highestHeldPoliticalStation,
            bookingLocation: _bookingLocation,
            bailOrBond: _bailOrBond,
            charges: _charges,
            rarity: _rarity
            uri: _uri
        });

        uint256 tokenId = tokenIdCounter;
        politicians[tokenId] = newPolitician;
        politiciansBySeries[_series].push(newPolitician);

        tokenIdCounter++;
    }

    // Function to get all Politicians
    function getAllPoliticians() public view returns (string[] memory, uint256[] memory, string[] memory) {
        string[] memory names = new string[](tokenIdCounter);
        uint256[] memory numbers = new uint256[](tokenIdCounter);
        string[] memory series = new string[](tokenIdCounter);
        for (uint256 i = 0; i < tokenIdCounter; i++) {
            names[i] = politicians[i].name;
            numbers[i] = politicians[i].number;
            series[i] = politicians[i].series;
        }
        return (names, numbers, series);
    }

    function getDefaultDropRates() public view returns (uint256[] memory) {
        uint256[] memory rates = new uint256[](6);
        rates[0] = defaultDropRates["Common"];
        rates[1] = defaultDropRates["Uncommon"];
        rates[2] = defaultDropRates["Rare"];
        rates[3] = defaultDropRates["Holo Rare"];
        rates[4] = defaultDropRates["Ultra Rare"];
        rates[5] = defaultDropRates["Secret Rare"];
        return rates;
    }

    function updateDefaultDropRates(uint256[] memory newDropRates) public onlyRole(DEFAULT_ADMIN_ROLE) {
        string[] memory rarities = ["Common", "Uncommon", "Rare", "Holo Rare", "Ultra Rare", "Secret Rare"];
        for (uint256 i = 0; i < newDropRates.length; i++) {
            if (newDropRates[i] > 0) {
                defaultDropRates[rarities[i]] = newDropRates[i];
            }
        }
    }

    function createNewSeries(string memory name, string memory uri, uint256 maxPacks, uint256 packPrice, uint256[] memory cardIds, uint256[] memory dropRates) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(name).length > 0, "Series name cannot be empty");
        require(maxPacks > 0, "Max packs must be greater than zero");

        Series storage newSeries = seriesMapping[name];
        newSeries.name = name;
        newSeries.baseUri = baseUri;
        newSeries.uri = uri;
        newSeries.maxPacks = maxPacks;
        newSeries.packPrice = packPrice;
        newSeries.cardIds = cardIds;

        string[] memory rarities = ["Common", "Uncommon", "Rare", "Holo Rare", "Ultra Rare", "Secret Rare"];
        for (uint256 i = 0; i < dropRates.length; i++) {
            if (dropRates[i] > 0) {
                newSeries.dropRates[rarities[i]] = dropRates[i];
            } else {
                newSeries.dropRates[rarities[i]] = defaultDropRates[rarities[i]];
            }
        }

        seriesList.push(name);
        emit SeriesCreated(name);
    }

    // Update the mintedPacks for a given series
    function updateMintedPacks(string memory _seriesName, uint256 newMintedPacks) public {
        // Ensure only the minting contract can call this function
        require(msg.sender == address(corruptionPacks), "Unauthorized");

        Series storage seriesToUpdate = seriesMapping[_seriesName];
        require(bytes(seriesToUpdate.name).length > 0, "Series does not exist");

        // Update the mintedPacks field
        seriesToUpdate.mintedPacks = newMintedPacks;
    }

    function getAllSeries() public view returns (string[] memory) {
        return seriesList;
    }

    function getSeriesInfo(string memory name) public view returns (Series memory) {
        return seriesMapping[name];
    }

    // Function to get Politician details by series
    function getPoliticiansBySeries(string memory _series) public view returns (string[] memory, uint256[] memory, uint256[] memory) {
        Politician[] memory politicians = politiciansBySeries[_series];
        string[] memory names = new string[](politicians.length);
        uint256[] memory numbers = new uint256[](politicians.length);
        uint256[] memory rarities = new uint256[](politicians.length);
        for (uint256 i = 0; i < politicians.length; i++) {
            names[i] = politicians[i].name;
            numbers[i] = politicians[i].number;
            rarities[i] = politicians[i].rarity;
        }
        return (names, numbers, rarities);
    }

    function mintPolitician(string memory series, uint256 numPacks, address userAddress) public onlyRole(CORRUPTION_PACKS_ROLE) {
        require(bytes(seriesMapping[series].name).length > 0, "Invalid series");
        require(numPacks > 0, "Number of packs must be greater than zero");
        require(userAddress != address(0), "Invalid user address");

        Politician[] memory politiciansInSeries = politiciansBySeries[series];
        uint256 totalMints = 3 * numPacks;

        for (uint256 i = 0; i < totalMints; i++) {
            uint256 randNum = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), userAddress, block.timestamp, nonce))) % 100;
            uint256 accumulatedRate = 0;

            for (uint256 j = 0; j < politiciansInSeries.length; j++) {
                accumulatedRate += seriesMapping[series].dropRates[politiciansInSeries[j].rarity];
                if (randNum < accumulatedRate) {
                    _mintPolitician(politiciansInSeries[j], userAddress);
                    break;
                }
            }
            nonce++;
        }
    }

    function _mintPolitician(Politician memory politician, address to) private {
        uint256 tokenId = tokenIdCounter;
        politicians[tokenId] = politician;

        // Mint the NFT and assign it to 'to' address
        super._mint(to, tokenId);

        tokenIdCounter++;
    }
}