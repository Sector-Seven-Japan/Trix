// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplaceWithERC20 is ReentrancyGuard {
    struct Listing {
        uint256 price;
        address seller;
        bytes32 group;
    }

    struct Bid {
        uint256 price;
        address buyer;
    }

    IERC20 public paymentToken;

    mapping(address => mapping(uint256 => Listing)) public listings;
    mapping(bytes32 => Bid) public groupBids;
    mapping(bytes32 => address[]) public groupContracts;
    mapping(bytes32 => mapping(address => uint256[])) public groupTokenIds;

    event NFTListed(address indexed nftContract, uint256 indexed tokenId, uint256 price, address indexed seller, bytes32 group);
    event NFTSold(address indexed nftContract, uint256 indexed tokenId, uint256 price, address indexed buyer);
    event NFTListingCancelled(address indexed nftContract, uint256 indexed tokenId, address indexed seller);
    event GroupBidPlaced(bytes32 indexed group, uint256 price, address indexed buyer);
    event GroupBidMatched(address indexed nftContract, uint256 indexed tokenId, uint256 price, address indexed buyer);

    constructor(address _paymentToken) {
        paymentToken = IERC20(_paymentToken);
    }

    modifier isOwner(address nftContract, uint256 tokenId, address spender) {
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == spender, "Not the owner");
        _;
    }

    modifier notListed(address nftContract, uint256 tokenId) {
        require(listings[nftContract][tokenId].price == 0, "Already listed");
        _;
    }

    modifier isListed(address nftContract, uint256 tokenId) {
        require(listings[nftContract][tokenId].price > 0, "Not listed");
        _;
    }

    function listNFT(address nftContract, uint256 tokenId, uint256 price, bytes32 group)
        external
        isOwner(nftContract, tokenId, msg.sender)
        notListed(nftContract, tokenId)
    {
        require(price > 0, "Price > 0");
        require(IERC721(nftContract).getApproved(tokenId) == address(this), "Not approved");

        listings[nftContract][tokenId] = Listing(price, msg.sender, group);
        groupTokenIds[group][nftContract].push(tokenId);
        groupContracts[group].push(nftContract);

        emit NFTListed(nftContract, tokenId, price, msg.sender, group);
    }

    function cancelListing(address nftContract, uint256 tokenId)
        external
        isOwner(nftContract, tokenId, msg.sender)
        isListed(nftContract, tokenId)
    {
        bytes32 group = listings[nftContract][tokenId].group;
        delete listings[nftContract][tokenId];
        _removeTokenIdFromGroup(group, nftContract, tokenId);

        emit NFTListingCancelled(nftContract, tokenId, msg.sender);
    }

    function buyNFT(address nftContract, uint256 tokenId)
        external
        nonReentrant
        isListed(nftContract, tokenId)
    {
        Listing storage listedItem = listings[nftContract][tokenId];
        require(paymentToken.transferFrom(msg.sender, listedItem.seller, listedItem.price), "Payment failed");

        bytes32 group = listedItem.group;
        delete listings[nftContract][tokenId];
        _removeTokenIdFromGroup(group, nftContract, tokenId);

        IERC721(nftContract).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
        emit NFTSold(nftContract, tokenId, listedItem.price, msg.sender);
    }

    function placeGroupBid(bytes32 group, uint256 price) external {
        require(price > 0, "Price > 0");
        require(groupBids[group].buyer == address(0), "Bid exists");
        require(paymentToken.transferFrom(msg.sender, address(this), price), "Transfer failed");

        groupBids[group] = Bid(price, msg.sender);
        emit GroupBidPlaced(group, price, msg.sender);

        // 自動マッチング処理
        address[] storage contracts = groupContracts[group];
        for (uint i = 0; i < contracts.length; i++) {
            address nftContract = contracts[i];
            uint256[] storage tokenIds = groupTokenIds[group][nftContract];

            for (uint j = 0; j < tokenIds.length; j++) {
                uint256 tokenId = tokenIds[j];
                Listing storage listing = listings[nftContract][tokenId];
                if (listing.price <= price && listing.seller != address(0)) {
                    address seller = listing.seller;
                    delete listings[nftContract][tokenId];
                    delete groupBids[group];

                    _removeTokenIdFromGroup(group, nftContract, tokenId);

                    require(paymentToken.transfer(seller, listing.price), "Pay seller fail");
                    IERC721(nftContract).safeTransferFrom(seller, msg.sender, tokenId);

                    emit GroupBidMatched(nftContract, tokenId, listing.price, msg.sender);
                    return;
                }
            }
        }
    }

    function _removeTokenIdFromGroup(bytes32 group, address nftContract, uint256 tokenId) internal {
        uint256[] storage tokens = groupTokenIds[group][nftContract];
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
        // グループ内に tokenId が存在しない場合は何もしない
    }

    function getListing(address nftContract, uint256 tokenId) external view returns (Listing memory) {
        return listings[nftContract][tokenId];
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        require(bytes(source).length <= 32, "Too long");
        assembly {
            result := mload(add(source, 32))
        }
    }
}
