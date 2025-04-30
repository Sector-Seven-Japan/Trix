// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract BCM is ERC721Enumerable {
    uint256 private _tokenIds;
    address private _owner;

    mapping(uint256 => uint16) private _tokenGroups;
    mapping(uint16 => uint256[]) private _groupToTokenIds;

    event NFTMinted(address indexed to, uint256 indexed tokenId, uint16 group);

    constructor() ERC721("BCM", "BCM") {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    function mintNFTWithGroup(
        address recipient,
        uint16 group
    ) public onlyOwner returns (uint256) {
        _tokenIds++;
        uint256 newId = _tokenIds;
        _mint(recipient, newId);
        _tokenGroups[newId] = group;
        _groupToTokenIds[group].push(newId);
        emit NFTMinted(recipient, newId, group);
        return newId;
    }

    function mintGroupNFTs(
        address recipient,
        uint16 group,
        uint256 amount
    ) public onlyOwner returns (uint256[] memory) {
        require(amount > 0 && amount <= 100, "Invalid mint amount");
        uint256[] memory minted = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            _tokenIds++;
            uint256 id = _tokenIds;
            _mint(recipient, id);
            _tokenGroups[id] = group;
            _groupToTokenIds[group].push(id);
            minted[i] = id;
            emit NFTMinted(recipient, id, group);
        }
        return minted;
    }

    function getOwnedTokenIds(address owner)
        external
        view
        returns (uint256[] memory tokenIds)
    {
        uint256 balance = balanceOf(owner);
        tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
    }

    function approveAllOwnedTo(address marketplace) external {
        uint256 balance = balanceOf(msg.sender);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            approve(marketplace, tokenId);
        }
    }

    function getTokenGroup(uint256 tokenId)
        external
        view
        returns (uint16)
    {
        return _tokenGroups[tokenId];
    }

    function getGroupTokenIds(uint16 group)
        external
        view
        returns (uint256[] memory)
    {
        return _groupToTokenIds[group];
    }
}
