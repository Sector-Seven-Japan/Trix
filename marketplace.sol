// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplaceWithERC20 is ReentrancyGuard {
    struct Listing {
        uint256 price;
        address seller;
        string group;
    }

    struct Bid {
        uint256 price;
        address buyer;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;
    mapping(string => Bid) public groupBids;
    IERC20 public paymentToken;
    
    struct ListedNFT {
        address nftContract;
        uint256 tokenId;
    }
    
    ListedNFT[] public listedNFTs;  // 出品されているNFTリスト

    event NFTListed(address indexed nftContract, uint256 indexed tokenId, uint256 price, address indexed seller, string group);
    event NFTSold(address indexed nftContract, uint256 indexed tokenId, uint256 price, address indexed buyer);
    event NFTListingCancelled(address indexed nftContract, uint256 indexed tokenId, address indexed seller);
    event GroupBidPlaced(string indexed group, uint256 price, address indexed buyer);
    event GroupBidMatched(address indexed nftContract, uint256 indexed tokenId, uint256 price, address indexed buyer);

    constructor(address _paymentToken) {
        paymentToken = IERC20(_paymentToken);
    }

    modifier isOwner(address nftContract, uint256 tokenId, address spender) {
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == spender, "Not the owner of the NFT");
        _;
    }

    modifier notListed(address nftContract, uint256 tokenId) {
        require(listings[nftContract][tokenId].price == 0, "NFT is already listed");
        _;
    }

    modifier isListed(address nftContract, uint256 tokenId) {
        require(listings[nftContract][tokenId].price > 0, "NFT is not listed");
        _;
    }

    function listNFT(address nftContract, uint256 tokenId, uint256 price, string memory group) 
        external 
        isOwner(nftContract, tokenId, msg.sender) 
        notListed(nftContract, tokenId)
    {
        require(price > 0, "Price must be greater than zero");

        IERC721 nft = IERC721(nftContract);
        require(nft.getApproved(tokenId) == address(this), "Marketplace not approved");

        listings[nftContract][tokenId] = Listing(price, msg.sender, group);
        listedNFTs.push(ListedNFT(nftContract, tokenId));  // 出品リストに追加

        emit NFTListed(nftContract, tokenId, price, msg.sender, group);
    }

    function placeGroupBid(string memory group, uint256 price) external {
        require(price > 0, "Price must be greater than zero");
        require(groupBids[group].buyer == address(0), "Group bid already exists");
        require(paymentToken.transferFrom(msg.sender, address(this), price), "Payment transfer failed");

        groupBids[group] = Bid(price, msg.sender);
        emit GroupBidPlaced(group, price, msg.sender);

        // 既存の出品NFTとマッチングするか確認
        for (uint256 i = 0; i < listedNFTs.length; i++) {
            address nftContract = listedNFTs[i].nftContract;
            uint256 tokenId = listedNFTs[i].tokenId;
            Listing memory listing = listings[nftContract][tokenId];

            if (keccak256(bytes(listing.group)) == keccak256(bytes(group)) && listing.price <= price) {
                delete groupBids[group];
                delete listings[nftContract][tokenId];

                // NFT売買成立
                require(paymentToken.transfer(listing.seller, listing.price), "Payment transfer failed");
                IERC721(nftContract).safeTransferFrom(listing.seller, msg.sender, tokenId);

                emit GroupBidMatched(nftContract, tokenId, listing.price, msg.sender);

                // 出品リストから削除
                _removeListedNFT(i);
                break;
            }
        }
    }

    function _removeListedNFT(uint256 index) internal {
        require(index < listedNFTs.length, "Index out of bounds");

        listedNFTs[index] = listedNFTs[listedNFTs.length - 1];
        listedNFTs.pop();
    }

    function cancelListing(address nftContract, uint256 tokenId) 
        external 
        isOwner(nftContract, tokenId, msg.sender) 
        isListed(nftContract, tokenId)
    {
        delete listings[nftContract][tokenId];

        // 出品リストから削除
        for (uint256 i = 0; i < listedNFTs.length; i++) {
            if (listedNFTs[i].nftContract == nftContract && listedNFTs[i].tokenId == tokenId) {
                _removeListedNFT(i);
                break;
            }
        }

        emit NFTListingCancelled(nftContract, tokenId, msg.sender);
    }

    function buyNFT(address nftContract, uint256 tokenId) 
        external 
        nonReentrant 
        isListed(nftContract, tokenId)
    {
        Listing memory listedItem = listings[nftContract][tokenId];
        require(paymentToken.transferFrom(msg.sender, listedItem.seller, listedItem.price), "Payment transfer failed");

        delete listings[nftContract][tokenId];

        // 出品リストから削除
        for (uint256 i = 0; i < listedNFTs.length; i++) {
            if (listedNFTs[i].nftContract == nftContract && listedNFTs[i].tokenId == tokenId) {
                _removeListedNFT(i);
                break;
            }
        }

        IERC721(nftContract).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
        emit NFTSold(nftContract, tokenId, listedItem.price, msg.sender);
    }

    function getListing(address nftContract, uint256 tokenId) 
        external 
        view 
        returns (Listing memory)
    {
        return listings[nftContract][tokenId];
    }
}
