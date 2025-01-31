// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract BCM is ERC721URIStorage {
    uint256 private _tokenIds;
    address private _owner;

    // マッピングでグループを管理
    mapping(uint256 => string) private _tokenGroups;

    constructor() ERC721("BCM", "BCM") {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    // グループを指定してNFTを発行
    function mintNFTWithGroup(
        address recipient,
        string memory tokenURI,
        string memory group
    ) public onlyOwner returns (uint256) {
        _tokenIds++;
        uint256 newItemId = _tokenIds;
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        // グループを設定
        _tokenGroups[newItemId] = group;

        return newItemId;
    }

    // 特定のNFTのグループを取得
    function getTokenGroup(uint256 tokenId) public view returns (string memory) {
        return _tokenGroups[tokenId];
    }
}
