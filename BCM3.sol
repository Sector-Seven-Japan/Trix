// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract BCM is ERC721Enumerable {
    uint256 private _tokenIds;
    address private _owner;

    mapping(uint256 => string) private _tokenGroups;
    mapping(string => uint256[]) private _groupToTokenIds;

    event NFTMinted(address indexed to, uint256 indexed tokenId, string group);

    constructor() ERC721("BCM", "BCM") {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    function mintNFTWithGroup(address recipient, string memory group)
        public onlyOwner returns (uint256)
    {
        _tokenIds++;
        uint256 newId = _tokenIds;
        _mint(recipient, newId);
        _tokenGroups[newId] = group;
        _groupToTokenIds[group].push(newId);

        emit NFTMinted(recipient, newId, group);
        return newId;
    }

    function mintGroupNFTs(address recipient, string memory group, uint256 amount)
        public onlyOwner returns (uint256[] memory)
    {
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

    function getTokenGroup(uint256 tokenId) external view returns (string memory) {
        return _tokenGroups[tokenId];
    }

    function getGroupTokenIds(string memory group) external view returns (uint256[] memory) {
        return _groupToTokenIds[group];
    }
}
