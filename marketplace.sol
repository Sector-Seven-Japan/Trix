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

    // NFT Contract Address => Token ID => Listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    // Group Name => Bid (stores bids by group)
    mapping(string => Bid) public groupBids;

    IERC20 public paymentToken; // ERC20トークン（例: USDT）

    event NFTListed(address indexed nftContract, uint256 indexed tokenId, uint256 price, address indexed seller, string group);
    event NFTSold(address indexed nftContract, uint256 indexed tokenId, uint256 price, address indexed buyer);
    event NFTListingCancelled(address indexed nftContract, uint256 indexed tokenId, address indexed seller);
    event GroupBidPlaced(string indexed group, uint256 price, address indexed buyer);
    event GroupBidMatched(address indexed nftContract, uint256 indexed tokenId, uint256 price, address indexed buyer);

    constructor(address _paymentToken) {
        paymentToken = IERC20(_paymentToken); // 支払いに使うERC20トークン（例: USDTのアドレス）
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

    // Function to list an NFT for sale, including its group
    function listNFT(address nftContract, uint256 tokenId, uint256 price, string memory group) 
        external 
        isOwner(nftContract, tokenId, msg.sender) 
        notListed(nftContract, tokenId)
    {
        require(price > 0, "Price must be greater than zero");

        IERC721 nft = IERC721(nftContract);
        require(nft.getApproved(tokenId) == address(this), "Marketplace not approved");

        listings[nftContract][tokenId] = Listing(price, msg.sender, group);
        emit NFTListed(nftContract, tokenId, price, msg.sender, group);

        // Check if there's a matching group bid
        Bid memory bid = groupBids[group];
        if (bid.price >= price && bid.buyer != address(0)) {
            delete groupBids[group];
            delete listings[nftContract][tokenId];

            // Transfer the NFT and payment
            require(paymentToken.transferFrom(bid.buyer, msg.sender, price), "Payment transfer failed");
            IERC721(nftContract).safeTransferFrom(msg.sender, bid.buyer, tokenId);

            emit GroupBidMatched(nftContract, tokenId, price, bid.buyer);
        }
    }

    // Function to place a bid for any NFT in a specific group
    function placeGroupBid(string memory group, uint256 price) external {
        require(price > 0, "Price must be greater than zero");

        Bid memory existingBid = groupBids[group];
        require(existingBid.buyer == address(0), "Group bid already exists");

        require(paymentToken.transferFrom(msg.sender, address(this), price), "Payment transfer failed");

        groupBids[group] = Bid(price, msg.sender);
        emit GroupBidPlaced(group, price, msg.sender);
    }

    // Function to cancel a listed NFT
    function cancelListing(address nftContract, uint256 tokenId) 
        external 
        isOwner(nftContract, tokenId, msg.sender) 
        isListed(nftContract, tokenId)
    {
        delete listings[nftContract][tokenId];
        emit NFTListingCancelled(nftContract, tokenId, msg.sender);
    }

    // Function to buy a listed NFT
    function buyNFT(address nftContract, uint256 tokenId) 
        external 
        nonReentrant 
        isListed(nftContract, tokenId)
    {
        Listing memory listedItem = listings[nftContract][tokenId];
        require(paymentToken.transferFrom(msg.sender, listedItem.seller, listedItem.price), "Payment transfer failed");

        delete listings[nftContract][tokenId];

        IERC721(nftContract).safeTransferFrom(listedItem.seller, msg.sender, tokenId);

        emit NFTSold(nftContract, tokenId, listedItem.price, msg.sender);
    }

    // Function to get the listing details
    function getListing(address nftContract, uint256 tokenId) 
        external 
        view 
        returns (Listing memory)
    {
        return listings[nftContract][tokenId];
    }
}
