// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Imported libraries and contracts
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./PoliticalCorruptionControl.sol";
import "../seadrop/src-upgradeable/src/ERC721SeaDropUpgradeable.sol";
import "./lib/ValidationLib.sol";
import "./lib/StatisticsLib.sol";

// Main contract
contract PoliticalCorruptionPacksERC721Upgradable is Initializable, ERC721Upgradeable, OwnableUpgradeable, ERC721SeaDropUpgradeable, ReentrancyGuardUpgradeable {

    // State variables
    PoliticalCorruptionControl private controlContract;
    uint256 private packTokenIdCounter;
    string public seaDropSeries;
    uint256 public seaDropMaxSupply;
    mapping(address => uint256) private _tokensMintedByAddress;

    // Events
    event ControlContractAddressUpdated(address indexed newAddress);
    event MintPackSuccessful(address indexed minter, uint256 quantity);
    event MintSeaDropSuccessful(address indexed minter, uint256 quantity);
    event SeriesUpdated(string newSeries);
    event PublicDropUpdated();
    event AllowListUpdated();
    event PackOpened(address indexed opener, uint256 packTokenId);

    // Initialization function
    function initialize(string memory uri, address _controlContract, address[] memory allowedSeaDrop) public initializer nonReentrant {
        __ERC721_init(uri, "PoliticalCorruptionPacks");
        __Ownable_init();
        __ERC721SeaDrop_init(uri, "PoliticalCorruptionPacks", allowedSeaDrop);
        __ReentrancyGuard_init();
        controlContract = PoliticalCorruptionControl(_controlContract);
    }

    // Getter for control contract address
    function getControlContractAddress() public view returns (address) {
        return address(controlContract);
    }

    // Update control contract address
    function updateControlContractAddress(address _controlContractAddress) public onlyOwner nonReentrant {
        require(_controlContractAddress != address(0), "Cannot update to zero address");
        require(_controlContractAddress != address(controlContract), "Cannot update to the same address");
        controlContract = PoliticalCorruptionControl(_controlContractAddress);
        emit ControlContractAddressUpdated(_controlContractAddress);
    }

    // Mint packs
    function mintPack(address minter, uint256 quantity, string memory _seriesName) public payable nonReentrant {
        ValidationLib.requireNonZeroAddress(minter);
        ValidationLib.requirePositiveQuantity(quantity);
        PoliticalCorruptionControl.Series memory seriesInfo = controlContract.getSeriesInfo(_seriesName);
        ValidationLib.requireSeriesExistence(_seriesName, seriesInfo.cardIds.length);
        ValidationLib.requireMaxSupply(seriesInfo.mintedPacks + quantity, seriesInfo.maxPacks);
        uint256 totalCost = seriesInfo.packPrice * quantity;
        ValidationLib.requireCorrectEthAmount(msg.value, totalCost);

        uint256 newPackTokenIdCounter = packTokenIdCounter;

        // Conditional Minting logic
        if (quantity == 1) {
            _safeMint(minter, newPackTokenIdCounter);
            newPackTokenIdCounter++;
        } else {
            for (uint256 i = 0; i < quantity; i++) {
                _mint(minter, newPackTokenIdCounter);
                newPackTokenIdCounter++;
            }
        }

        // Update state variables in one go
        packTokenIdCounter = newPackTokenIdCounter;
        _tokensMintedByAddress[minter] = StatisticsLib.updateTokensMintedByAddress(_tokensMintedByAddress[minter], quantity);
        controlContract.updateMintedPacks(_seriesName, StatisticsLib.updateMintedPacks(_seriesName, seriesInfo.mintedPacks, quantity));

        emit MintPackSuccessful(minter, quantity);
    }

    // Update SeaDrop series
    function setSeaDropSeries(string memory _newSeries) external onlyOwner nonReentrant {
        seaDropSeries = _newSeries;
        PoliticalCorruptionControl.Series memory seriesInfo = controlContract.getSeriesInfo(_newSeries);
        seaDropMaxSupply = seriesInfo.maxPacks;
        emit SeriesUpdated(_newSeries);
    }

    // Mint SeaDrop
    function mintSeaDrop(address minter, uint256 quantity) external override nonReentrant {
        _onlyAllowedSeaDrop(msg.sender);
        require(packTokenIdCounter + quantity <= seaDropMaxSupply, "Max supply reached for SeaDrop");

        // Minting logic
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(minter, packTokenIdCounter);
            packTokenIdCounter++;
        }

        // Update state variables
        _tokensMintedByAddress[minter] += quantity;
        controlContract.updateMintedPacks(seaDropSeries, packTokenIdCounter);

        emit MintSeaDropSuccessful(minter, quantity);
    }

    // Update public drop configuration
    function updatePublicDrop(PublicDrop calldata publicDrop) external override onlyOwner nonReentrant {
        _onlyAllowedSeaDrop(msg.sender);
        ISeaDropUpgradeable(msg.sender).updatePublicDrop(publicDrop);
        emit PublicDropUpdated();
    }

    // Update allow list
    function updateAllowList(AllowListData calldata allowListData) external override onlyOwner nonReentrant {
        _onlyAllowedSeaDrop(msg.sender);
        ISeaDropUpgradeable(msg.sender).updateAllowList(allowListData);
        emit AllowListUpdated();
    }

    // Get minting statistics
    function getMintStats(address minter) external view override returns (uint256 minterNumMinted, uint256 currentTotalSupply, uint256 maxSupply) {
        minterNumMinted = _numberMinted(minter);
        currentTotalSupply = packTokenIdCounter;
        maxSupply = seaDropMaxSupply;
    }

    // Internal function to get number of tokens minted by an address
    function _numberMinted(address minter) internal view returns (uint256) {
        return _tokensMintedByAddress[minter];
    }

    // Interface support check
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == type(INonFungibleSeaDropTokenUpgradeable).interfaceId;
    }

    // Open a pack
    function openPack(string memory _seriesName, uint256 packTokenId) public nonReentrant {
        // Validation checks
        PoliticalCorruptionControl.Series memory seriesInfo = controlContract.getSeriesInfo(_seriesName);
        require(seriesInfo.cardIds.length > 0, "Series does not exist");
        require(_exists(packTokenId) && ownerOf(packTokenId) == msg.sender, "You do not own this pack");

        // Burn the pack
        _burn(packTokenId);

        // Mint new tokens
        for (uint256 i = 0; i < 3; i++) {
            uint256 random = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, i)));
            uint256 tokenId = seriesInfo.cardIds[random % seriesInfo.cardIds.length];
            // Mint the Politician NFT here
            // PoliticianCards.mintPolitician(tokenId, msg.sender);
        }

        emit PackOpened(msg.sender, packTokenId);
    }
}