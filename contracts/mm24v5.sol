// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721, Strings} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

error MaxTokensMinted();
error EmptyNotPossible();
error MaxMintsNeedsToBeGreaterThanMintedNumber();
error OnlyForMinted();
error PayableWrong(uint256 value, uint256 payableRequired);


/// @title Get a license string
/// @author glbkst
/// @notice no further use
interface ILicenseInfo {
    /// @return license license as a string
    function getLicense() external view returns (string memory license);    
    /// @notice set license as a string
    function setLicense(string memory license) external;    
}

/// @title A flexible NFT contract
/// @author glbkst
/// @notice Can update the token uri any time, incrementally by changing the uri or by
///         setting token id ranges the uri can be differnt for those ids or be changed for newer mints
/// @dev Intended for L2 deployments, intended to be deployed as-is and set-up with an init call,
///       therefore it is deployed as paused.
contract MM24v5 is
    ERC721,
    ERC721URIStorage,
    ERC721Pausable,
    Ownable,
    ERC721Burnable,
    ReentrancyGuard,
    ILicenseInfo
{
    uint256 private _nextTokenId;
    uint256 private _maxMint;
    uint256 private _maxMintL;
    address private _receivingAddress;
    string private _newName;
    string private _licenseString;
    string private _currentUri;
    uint256 private _mintPayable;
    uint256 private _mintPayableL;
    uint256 private _mintNoL;

    /// @notice Contract deployed as paused.
    /// @param initialOwner owner of the contract
    constructor(
        address initialOwner,
        string memory NFTname
    ) ERC721(NFTname, "MM24v5") Ownable(initialOwner) {
        _pause();
        _nextTokenId = 1;
        _receivingAddress = owner();
        _maxMint = 2;
        _maxMintL = 1;
        _mintPayable = 200000 gwei;
        _mintPayableL = 1450000 gwei;
    }

    /// @notice init the NFT parameters with 1 call.
    /// @param uri sets the uri for all newly minted NFTs
    /// @param maxMint sets the maximum number of mints
    function init(
        string memory uri,
        uint256 maxMint
    ) public onlyOwner {
        setUri(uri);
        if (maxMint >= 1) {
            setMaxMints(maxMint);
        }
        unpause();
    }

    /// @dev standard override it is intended to be always "", different token uri can
    ///      otherwise easily break the contract because this is always concat in a base class
    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    /// @notice set the token uri
    /// @param uri new uri for new mints
    function setUri(string memory uri) public onlyOwner {
        if (bytes(uri).length == 0) revert EmptyNotPossible();
        _currentUri = uri;
    }

    /// @notice update the token uri of *all* tokens, this can be potentially
    ///        cause high gas fees for many tokens. But for convenience if this is needed.
    function updateUri() public onlyOwner returns (uint256 updateNumber) {
        uint256 updated = 0;
        for (uint256 i = 1; i < _nextTokenId; ++i) {
            string memory turi = tokenURI(i);
            if (!Strings.equal(turi, _currentUri)) {
                _setTokenURI(i, _currentUri);
                ++updated;
            }
        }
        return updated;
    }

    /// @notice change the uri for a range of tokens
    /// @param uri uri to be set for existing tokens
    /// @param idx1 start of token id to be set
    /// @param idx2 end of token id to be set, must be <= mintNumber
    function setUriRange(
        string memory uri,
        uint256 idx1,
        uint256 idx2
    ) public onlyOwner returns (uint256 setNumber) {
        if (idx2 > _nextTokenId || idx1 > _nextTokenId) revert OnlyForMinted();
        setNumber = 0;
        for (uint256 i = idx1; i <= idx2; ++i) {
            string memory turi = tokenURI(i);
            if (bytes(turi).length != 0) {
                _setTokenURI(i, uri);
            }
            ++setNumber;
        }
        return setNumber;
    }

    /// @notice set a new name for the NFT
    /// @param name_new name
    function setName(string memory name_new) public onlyOwner {
        _newName = name_new;
    }

    /// @inheritdoc ERC721
    function name() public view override returns (string memory) {
        if (bytes(_newName).length > 0) {
            return _newName;
        }
        return super.name();
    }

    /// @notice set a new maximum for mints
    /// @param maxNo new max, must be > mintNumber
    function setMaxMints(uint256 maxNo) public onlyOwner {
        if (_nextTokenId > maxNo)
            revert MaxMintsNeedsToBeGreaterThanMintedNumber();
        _maxMint = maxNo;
    }

    /// @notice return current maximum for mints
    function maxMints() public view returns (uint256 maxno) {
        return _maxMint;
    }

    /// @notice set a new maximum for mints big
    /// @param maxNo new max, must be > mintNumber big
    function setMaxMintsL(uint256 maxNo) public onlyOwner {
        if (_mintNoL >= maxNo)
            revert MaxMintsNeedsToBeGreaterThanMintedNumber();
        _maxMintL = maxNo;
    }

    /// @notice return current maximum for mints
    function maxMintsL() public view returns (uint256 maxno) {
        return _maxMintL;
    }


    /// @notice set new address used for withdraw calls
    ///    default at deployment is the deployer. Useful for splits contracts e.g.
    /// @param withdrawAddress  new address for withdraw
    function setWithdrawAddress(
        address withdrawAddress
    ) public onlyOwner returns (address) {
        _receivingAddress = withdrawAddress;
        return _receivingAddress;
    }

    /// @notice pause the contract functions, for mint() mainly
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice unpause the contract functions, for mint() mainly
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @return number current number of minted NFTs
    function mintNumber() public view returns (uint256 number) {
        return _nextTokenId - 1;
    }

    /// @return number current number of minted NFTs
    function mintNumberL() public view returns (uint256 number) {
        return _mintNoL;
    }

    /// @return amount payable amount, in gwei, 1.000.000.000 = 1 eth
    function mintPayable() public view returns (uint256 amount) {
        return _mintPayable / 1 gwei;
    }

    /// @notice set the required payable for the mint function
    /// @param amount amount in gwei, 1.000.000.000 = 1 eth
    function setMintPayable(uint256 amount) public onlyOwner {
        amount = 1 gwei * amount;
        _mintPayable = amount;
    }

    /// @return amount payable amount, in gwei, 1.000.000.000 = 1 eth
    function mintPayableL() public view returns (uint256 amount) {
        return _mintPayableL / 1 gwei;
    }

    /// @notice set the required payable for the mint function
    /// @param amount amount in gwei, 1.000.000.000 = 1 eth
    function setMintPayableL(uint256 amount) public onlyOwner {
        amount = 1 gwei * amount;
        _mintPayableL = amount;
    }

    /// @notice withdraw the balance of the contract to the withdraw address
    ///     by default the owner or a later set withdraw address
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        address payable recipient;
        if (_receivingAddress != owner()) {
            recipient = payable(_receivingAddress);
        } else {
            recipient = payable(owner());
        }
        Address.sendValue(recipient, amount);
    }

    /// @notice the public mint function
    function mint() external payable {
        if (msg.value != _mintPayable
            && msg.value != _mintPayableL) revert PayableWrong(msg.value, _mintPayable);
        if(msg.value == _mintPayableL) {
            ++_mintNoL;
            if(_mintNoL > _maxMintL) revert MaxTokensMinted();
        }
        mintInternal();       
    }

     function mintInternal() private nonReentrant {
        if( _nextTokenId + 1 > _maxMint) revert MaxTokensMinted();
        
        address to = _msgSender();
        safeMintInternal(to);
    }

    /// private mint function
    /// @param to address to mint to
    function safeMintInternal(address to) private {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _currentUri);
    }

    function safeMint(address to) public onlyOwner {
        safeMintInternal(to);
    }

    /// @dev override to update address here
    /// @inheritdoc Ownable
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
        _receivingAddress = owner();
    }

    /// @inheritdoc ILicenseInfo
    function getLicense() external view returns (string memory license) {
        license = _licenseString;
    }

    /// @inheritdoc ILicenseInfo
    function setLicense(string memory license) public override onlyOwner {
        _licenseString = license;
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Pausable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
