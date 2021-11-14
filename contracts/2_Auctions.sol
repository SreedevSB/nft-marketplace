// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Auctions{
    using Counters for Counters.Counter;
    Counters.Counter private auctionIds;
    struct Auction {
        uint256 highestBid;
        uint256 minAmount;
        uint256 closingTime;
        address highestBidder;
        address originalOwner;
        address nftContract;
        uint256 tokenId;
        bool isActive;
    }
    
    // Auction id => Auction data
    mapping(uint256 => Auction) public idToAuction;
    
    
    function openAuction(
        address nftContract, 
        uint256 tokenId, 
        uint256 minAmount, 
        uint256 duration) external{
        
        //require(idToAuction[tokenId] == false, "Auction alredy active for the item");
        require(ERC721(nftContract).ownerOf(tokenId) == msg.sender, "Not NFT owner");
        
        ERC721(nftContract).safeTransferFrom(msg.sender,address(this), tokenId);
        
        auctionIds.increment();
        uint256 auctionId = auctionIds.current();
        idToAuction[auctionId] = Auction(
            0,
            minAmount,
            block.timestamp + duration,
            address(0),
            msg.sender,
            nftContract,
            tokenId,
            true
        );
    }
        
    function placeBid (
        uint256 auctionId, 
        uint256 amount )  external payable {
        require(idToAuction[auctionId].closingTime > block.timestamp, "Auction for the item ended");
        require(idToAuction[auctionId].highestBid < amount, "Bid amount should be higher than highestBid");
        require(idToAuction[auctionId].highestBid > 0, "Bid amount should be higher than highestBid");
        payable(idToAuction[auctionId].highestBidder).transfer(
            idToAuction[auctionId].highestBid
            );
        
        idToAuction[auctionId].highestBidder = msg.sender;
        idToAuction[auctionId].highestBid = msg.value;
    }
    function endAuction(uint256 auctionId) external{
        require(idToAuction[auctionId].closingTime < block.timestamp, "Auction still live");
        require(idToAuction[auctionId].isActive == true, "Auction already ended");
        
        idToAuction[auctionId].isActive = false;
        payable(idToAuction[auctionId].originalOwner).transfer(idToAuction[auctionId].highestBid);
        ERC721(idToAuction[auctionId].nftContract).safeTransferFrom(
            address(this), 
            idToAuction[auctionId].highestBidder, 
            idToAuction[auctionId].tokenId);
    }

}