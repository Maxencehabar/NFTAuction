// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;


// 
interface IERC721 {
    function transfer(address, uint) external;
    function transferFrom(address,address,uint) external ;
    
}

contract Auction {

    event Start();
    event End(address highestBidder, uint highestBid);
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);

    address payable public seller;
    bool public started;
    bool public ended;
    uint public endAt;

    IERC721 public nft;
    uint public nftId;

    uint public highestBid;
    address public highestBidder;

    mapping(address => uint) public bids;

    constructor () {
        seller = payable(msg.sender);
    }

    function start(uint startingBid, IERC721 _nft, uint _nftId) external  {
        require(!started, "Already started");
        require(msg.sender == seller, "you did not start the auction");
        started = true;
        highestBid = startingBid;
        endAt = block.timestamp + 7 days;
        // emiting the event 

        nft = _nft;
        nftId = _nftId;
        // Sending the nft to the smart contract
        nft.transferFrom(msg.sender, address(this), nftId );
    
        emit Start();
    }

    function bid() external payable {
        require(started,"Not started");
        require(!ended,"Ended");
        require(msg.value > highestBid);

        if (highestBidder != address(0)){
            bids[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        
        emit Bid(highestBidder,highestBid);


    }

    function withdraw() external payable {
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        (bool sent, bytes memory data) = payable(msg.sender).call{value: bal}("");
        require(sent, "Error while withdrawing");
        
        emit Withdraw(msg.sender, bal);
    }

    function end() external {
        require(started,"You need to start first!");
        require(block.timestamp >= endAt, "Auction not finished");
        require(!ended, "Auction already ended");
        
        if(highestBidder != address(0)){
            nft.transfer(highestBidder,nftId);
            (bool sent, bytes memory data) = seller.call{value:highestBid}("");
            require(sent,"Could not pay");
        } else {
            nft.transfer(seller, nftId);
        }
        
        ended = true;


        emit End(highestBidder,highestBid);
    }

}