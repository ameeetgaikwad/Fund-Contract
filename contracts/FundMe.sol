// get funds from users
// withdraw funds
// set a minimum fuding value in usd

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "hardhat/console.sol";
import "./PriceConverter.sol";

error FundMe__NotOwner();

// Interfaces, Libraries, Contracts

/** @title A contract for crowd funding
 *  @author Amit Gaikwad
 *  @notice This contract is a demo a sample funding contract
 *  @dev This implements price feeds as our library
 */

contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;
    // State Variables
    mapping(address => uint256) public s_addressToAmountFunded;
    address[] private s_funders;
    // Could we make this constant?
    address private immutable i_owner;
    uint256 public constant MINMUM_USD = 10 * 1e18;
    AggregatorV3Interface public s_priceFeed;

    modifier onlyOwner() {
        // require(msg.sender==i_owner,"sender is not owner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // What if someone sends this contract ETH without calling the fund() function

    // receive() external payable {
    //     fund();
    // }

    // fallback() external payable {
    //     fund();
    // }

    function fund() public payable {
        //Want to be able to set a minimum fund amount in USD
        //1. How do we send ETH to this contract

        // require(getConversionRate(msg.value)>minimumUsd,"didn't send enough");
        require(
            msg.value.getConversionRate(s_priceFeed) > MINMUM_USD,
            "didn't send enough"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
        // What is reverting
        // undo any action before, and send remaining gas back
    }

    function withdraw() public payable onlyOwner {
        // require(msg.sender==owner,"sender is not owner");

        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0);
        //actually withdraw the funds

        // msg.sender=address
        // payable(msg.sender)=payable address

        // transfer (automatically revert the transaction if failed)
        // payable(msg.sender).transfer(address(this).balance);

        // send (doesn't automatically revert the transaction if failed, need to use "require")
        // bool sendSuccess=payable(msg.sender).send(address(this).balance);
        // require(sendSuccess,"Send Failed");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // Mappings can't me in memory

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed");
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    function contractAddress() public view returns (address) {
        return address(this);
    }
}
