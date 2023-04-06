// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "forge-std/console.sol";

interface IPriceOracle {
    function getPrice(address token) external view returns (uint256);
    function setPrice(address token, uint256 price) external;
}

contract DreamAcademyLending {
    uint256 public number;
    ERC20 usdc;
    uint256 usdc_amount;
    IPriceOracle IPO;
    mapping (address => uint256) loan_ledger;
    mapping (address => deposit_) deposit_ledger;
    uint borrow_block;
    struct deposit_{
        uint usdc_amount;
        uint eth_amount;
    }

    constructor(IPriceOracle _oracle, address _usdc) {
        IPO = IPriceOracle(_oracle);
        usdc = ERC20(_usdc);
    }
    function initializeLendingProtocol(address _usdc_) public payable {
        usdc.transferFrom(msg.sender, address(this), msg.value);
        usdc_update();   
    }
    function deposit(address tokenAddress, uint256 amount) external payable{
        if(tokenAddress == address(0)){   //ETH Deposit
            require(amount == msg.value && amount > 0, "error with your deposit amount");
            deposit_ledger[msg.sender].eth_amount += amount;
        }
        else{   //USDC Deposit
            require(amount > 0, "amount must be more than zero");
            usdc.transferFrom(msg.sender, address(this), amount);
            deposit_ledger[msg.sender].usdc_amount += amount;
            usdc_update();
        }

    }
    function borrow(address tokenAddress, uint256 amount) external {
        require(tokenAddress == address(usdc), "please check your tokenAddress again");
        require(usdc.balanceOf(address(this)) >= amount, "We don't have that much usdc required");
        interest_update(msg.sender);

        uint available_amount = borrow_amount(amount);
        require(available_amount >= amount, "amount too much");
        usdc.transfer(msg.sender, amount);
        loan_ledger[msg.sender] += amount;
        console.log("fdsa", block.number, loan_ledger[msg.sender]);
        borrow_block = block.number;
        usdc_update();
    }
    function borrow_amount(uint amount) public returns (uint) {
        (uint eth_price, uint usdc_price) = Price_Update();

        uint deposit_value = EtherToUsdc(deposit_ledger[msg.sender].eth_amount);
        return (deposit_value / 2) - loan_ledger[msg.sender];
    }
    function EtherToUsdc(uint amount) public returns (uint) {
        (uint eth_price, uint usdc_price) = Price_Update();

        return amount * eth_price / usdc_price;
    }
    function UsdcToEther(uint amount) public returns (uint) {
        (uint eth_price, uint usdc_price) = Price_Update();

        return amount * usdc_price / eth_price;
    }
    function repay(address tokenAddress, uint256 amount) external {
        require(tokenAddress == address(usdc), "please check your tokenAddress again");
        require(loan_ledger[msg.sender] >= amount, "please check your token amount");
        usdc.transferFrom(msg.sender, address(this), amount);
        loan_ledger[msg.sender] -= amount;
        usdc_update();
    }
    function liquidate(address user, address tokenAddress, uint256 amount) external payable{ 
        (uint eth_price, uint usdc_price) = Price_Update();
        require(amount>0, "amount should be more than zero");
        require(EtherToUsdc(deposit_ledger[user].eth_amount)*75/100 <= loan_ledger[user], "liquidation is not available yet");
        uint LIMIT_RATIO;

        if(UsdcToEther(loan_ledger[user]*usdc_price) < 100){
            LIMIT_RATIO = 100;
        }
        else{
            LIMIT_RATIO = 25;
        }
        if(tokenAddress == address(usdc)){
            require(amount <= loan_ledger[user] *  LIMIT_RATIO / 100);
        }
        else if(tokenAddress == address(0)){
            require(EtherToUsdc(amount) <= loan_ledger[user] * LIMIT_RATIO / 100);
        }
        usdc.transferFrom(msg.sender, address(this), amount);
        uint loan_amount = EtherToUsdc(loan_ledger[user]);
        uint ETH_Amount = loan_ledger[user] * amount / loan_amount;

        loan_ledger[user] -= amount;
        msg.sender.call{value: ETH_Amount}("");
    }
    function withdraw(address tokenAddress, uint256 amount) external {
        (uint ETH_Price, uint usdc_Price) = Price_Update();
        interest_update(msg.sender);

        if(tokenAddress == address(0)){  //ETH
            require(deposit_ledger[msg.sender].eth_amount >= amount);
            console.log(UsdcToEther(loan_ledger[msg.sender]));
            console.log((deposit_ledger[msg.sender].eth_amount-amount)*75/100);
            require((deposit_ledger[msg.sender].eth_amount-amount)*75/100 >= UsdcToEther(loan_ledger[msg.sender]));
            deposit_ledger[msg.sender].eth_amount -= amount;
            msg.sender.call{value: amount}("");
        }
        else{   //USDC
            require(deposit_ledger[msg.sender].usdc_amount >= amount);
            deposit_ledger[msg.sender].usdc_amount -= amount;
            usdc.transfer(msg.sender, amount);
            usdc_update();
        }
    }

    function usdc_update() public {
        usdc_amount = usdc.balanceOf(address(this));
    }
    function Price_Update() public returns (uint, uint){
        uint ETH_Price = IPO.getPrice(address(0));
        uint usdc_Price = IPO.getPrice(address(usdc));
        
        return (ETH_Price, usdc_Price);
    }

    function getAccruedSupplyAmount(address _addr) external payable returns (uint256) {

    }
    function interest_update(address user) public returns (uint){
        if(borrow_block < block.number && block.number != 1){
            uint interest = (block.number - borrow_block) * loan_ledger[user] * 1001 / 1000 / 86400;
            loan_ledger[user] += interest;
        }
    }
}
