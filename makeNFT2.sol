// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BCM is ERC721 {
    uint256 private _tokenIds;
    address private _owner;

    mapping(uint256 => string) private _tokenGroups;

    event NFTMinted(address indexed to, uint256 indexed tokenId, string group);

    constructor() ERC721("BCM", "BCM") {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    /// 単体ミント（URIなし、グループのみ）
    function mintNFTWithGroup(
        address recipient,
        string memory group
    ) public onlyOwner returns (uint256) {
        _tokenIds++;
        uint256 newItemId = _tokenIds;
        _mint(recipient, newItemId);
        _tokenGroups[newItemId] = group;

        emit NFTMinted(recipient, newItemId, group);
        return newItemId;
    }

    /// 一括ミント（最大100件まで）
    function mintGroupNFTs(
        address recipient,
        string memory group,
        uint256 amount
    ) public onlyOwner returns (uint256[] memory) {
        require(amount > 0 && amount <= 100, "Invalid mint amount");

        uint256[] memory mintedIds = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            _tokenIds++;
            uint256 newId = _tokenIds;
            _mint(recipient, newId);
            _tokenGroups[newId] = group;
            mintedIds[i] = newId;

            emit NFTMinted(recipient, newId, group);
        }

        return mintedIds;
    }

    /// トークンの属するグループを取得
    function getTokenGroup(uint256 tokenId) external view returns (string memory) {
        return _tokenGroups[tokenId];
    }
}
