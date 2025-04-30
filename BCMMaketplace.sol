// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplaceWithERC20 is ReentrancyGuard {
    IERC20 public paymentToken;

    mapping(address => mapping(uint256 => address)) public listings;
    mapping(bytes32 => address[]) public groupContracts;
    mapping(bytes32 => mapping(address => uint256[])) public groupTokenIds;

    event NFTListed(address indexed nftContract, uint256 indexed tokenId, uint256 price, address indexed seller, bytes32 group);
    event NFTSold(address indexed nftContract, uint256 indexed tokenId, uint256 price, address indexed buyer);
    event NFTListingCancelled(address indexed nftContract, uint256 indexed tokenId, address indexed seller);
    event ListingFailed(address indexed nftContract, uint256 indexed tokenId, string reason);
    event PurchaseFailed(address indexed nftContract, uint256 indexed tokenId, string reason);

    constructor(address _paymentToken) {
        paymentToken = IERC20(_paymentToken);
    }

    modifier isOwner(address nftContract, uint256 tokenId, address spender) {
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == spender, "Not the owner");
        _;
    }

    function listNFT(address nftContract, uint256 tokenId, bytes32 group)
        public
        isOwner(nftContract, tokenId, msg.sender)
        returns (bool success)
    {
        if (listings[nftContract][tokenId] != address(0)) {
            emit ListingFailed(nftContract, tokenId, "Already listed");
            return false;
        }
        if (IERC721(nftContract).getApproved(tokenId) != address(this)) {
            emit ListingFailed(nftContract, tokenId, "Not approved");
            return false;
        }

        listings[nftContract][tokenId] = msg.sender;
        groupTokenIds[group][nftContract].push(tokenId);
        groupContracts[group].push(nftContract);

        emit NFTListed(nftContract, tokenId, getGroupPrice(group), msg.sender, group);
        return true;
    }

    function listMany(address nftContract, uint256[] calldata tokenIds, bytes32 group) external returns (uint256[] memory listed) {
        listed = new uint256[](tokenIds.length);
        uint256 count = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            bool ok = listNFT(nftContract, tokenIds[i], group);
            if (ok) {
                listed[count] = tokenIds[i];
                count++;
            }
        }
        assembly { mstore(listed, count) }
    }

    function cancelListing(address nftContract, uint256 tokenId)
        external
        isOwner(nftContract, tokenId, msg.sender)
    {
        require(listings[nftContract][tokenId] != address(0), "Not listed");
        bytes32 group = getGroup(nftContract, tokenId);
        delete listings[nftContract][tokenId];
        _removeTokenIdFromGroup(group, nftContract, tokenId);
        emit NFTListingCancelled(nftContract, tokenId, msg.sender);
    }

    function buyNFT(address nftContract, uint256 tokenId) public nonReentrant returns (bool success) {
        if (listings[nftContract][tokenId] == address(0)) {
            emit PurchaseFailed(nftContract, tokenId, "Not listed");
            return false;
        }
        bytes32 group = getGroup(nftContract, tokenId);
        address seller = listings[nftContract][tokenId];
        uint256 price = getGroupPrice(group);

        if (!paymentToken.transferFrom(msg.sender, seller, price)) {
            emit PurchaseFailed(nftContract, tokenId, "Payment failed");
            return false;
        }

        delete listings[nftContract][tokenId];
        _removeTokenIdFromGroup(group, nftContract, tokenId);

        IERC721(nftContract).safeTransferFrom(seller, msg.sender, tokenId);
        emit NFTSold(nftContract, tokenId, price, msg.sender);
        return true;
    }

    function buyMany(address nftContract, uint256[] calldata tokenIds) external returns (uint256[] memory purchased) {
        purchased = new uint256[](tokenIds.length);
        uint256 count = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            bool ok = buyNFT(nftContract, tokenIds[i]);
            if (ok) {
                purchased[count] = tokenIds[i];
                count++;
            }
        }
        assembly { mstore(purchased, count) }
    }

    function buyUpTo(address nftContract, uint256[] calldata tokenIds, uint256 maxTotal) external returns (uint256[] memory purchased) {
        purchased = new uint256[](tokenIds.length);
        uint256 count = 0;
        uint256 totalSpent = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (listings[nftContract][tokenIds[i]] != address(0)) {
                bytes32 group = getGroup(nftContract, tokenIds[i]);
                uint256 price = getGroupPrice(group);

                if (totalSpent + price > maxTotal) {
                    emit PurchaseFailed(nftContract, tokenIds[i], "Budget exceeded");
                    continue;
                }
                if (!paymentToken.transferFrom(msg.sender, listings[nftContract][tokenIds[i]], price)) {
                    emit PurchaseFailed(nftContract, tokenIds[i], "Payment failed");
                    continue;
                }

                address seller = listings[nftContract][tokenIds[i]];
                delete listings[nftContract][tokenIds[i]];
                _removeTokenIdFromGroup(group, nftContract, tokenIds[i]);

                IERC721(nftContract).safeTransferFrom(seller, msg.sender, tokenIds[i]);
                emit NFTSold(nftContract, tokenIds[i], price, msg.sender);

                purchased[count] = tokenIds[i];
                count++;
                totalSpent += price;
            } else {
                emit PurchaseFailed(nftContract, tokenIds[i], "Not listed");
            }
        }
        assembly { mstore(purchased, count) }
    }

    function listUpTo(address nftContract, uint256[] calldata tokenIds, bytes32 group, uint256 maxCount) external returns (uint256[] memory listed) {
        listed = new uint256[](tokenIds.length);
        uint256 count = 0;
        for (uint256 i = 0; i < tokenIds.length && count < maxCount; i++) {
            bool ok = listNFT(nftContract, tokenIds[i], group);
            if (ok) {
                listed[count] = tokenIds[i];
                count++;
            }
        }
        assembly { mstore(listed, count) }
    }

    function getGroupPrice(bytes32 group) public pure returns (uint256) {
        bytes memory g = abi.encodePacked(group);
        if (g.length >= 2 && g[0] == "G" && g[1] == "r") {
            uint256 number = 0;
            for (uint256 i = 2; i < g.length; i++) {
                if (g[i] < 0x30 || g[i] > 0x39) revert("Invalid group");
                number = number * 10 + (uint8(g[i]) - 48);
            }
            return number * 1e6;
        }
        revert("Invalid group format");
    }

    function getGroup(address nftContract, uint256 tokenId) internal view returns (bytes32) {
        string[2] memory groupStrs = ["Group1", "Group2"];
        bytes32[] memory groups = new bytes32[](groupStrs.length);
        for (uint i = 0; i < groupStrs.length; i++) {
            groups[i] = stringToBytes32(groupStrs[i]);
        }

        for (uint256 g = 0; g < groups.length; g++) {
            uint256[] memory ids = groupTokenIds[groups[g]][nftContract];
            for (uint256 i = 0; i < ids.length; i++) {
                if (ids[i] == tokenId) return groups[g];
            }
        }
        revert("Group not found");
    }

    function _removeTokenIdFromGroup(bytes32 group, address nftContract, uint256 tokenId) internal {
        uint256[] storage tokens = groupTokenIds[group][nftContract];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        require(bytes(source).length <= 32, "Too long");
        assembly {
            result := mload(add(source, 32))
        }
    }
}
