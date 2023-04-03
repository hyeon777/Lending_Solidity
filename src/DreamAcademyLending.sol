// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./IPriceOracle.sol";

contract DreamAcademyLending {
    uint256 public number;
    ERC20 usdc;
    uint256 usdc_amount;
    mapping (address => uint256) loan_ledger;
    mapping (address => deposit_) deposit_ledger;

    struct deposit_{
        uint usdc_amount;
        uint eth_amount;
    }

    constructor(IPriceOracle _oracle, address _usdc) {
        IPriceOracle IPO = IPriceOracle(_oracle);
        usdc = ERC20(_usdc);
    }
    function initializeLendingProtocol(address _usdc_) public payable {
        usdc.transferFrom(msg.sender, address(this), msg.value);
        usdc_update();   
    }
    function deposit(address tokenAddress, uint256 amount) external payable{
        if(tokenAddress == address(0)){
            require(amount == msg.value && amount > 0, "error with value");
            deposit_ledger[msg.sender].eth_amount += amount;
        }
        else{
            require(amount > 0, "amount must be more than zero");
            ERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
            deposit_ledger[msg.sender].usdc_amount += amount;
            usdc_update();
        }

    }
    function borrow(address tokenAddress, uint256 amount) external {
        require(tokenAddress == address(usdc));
        require(usdc.balanceOf(address(this)) >= amount);
        usdc.transfer(msg.sender, amount);
        loan_ledger[msg.sender] += amount;
    }
    function repay(address tokenAddress, uint256 amount) external {
        require(tokenAddress == address(usdc));
        require(loan_ledger[msg.sender] >= amount);
        ERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        loan_ledger[msg.sender] -= amount;
    }
    function liquidate(address user, address tokenAddress, uint256 amount) external {

    }
    function withdraw(address tokenAddress, uint256 amount) external {
        if(tokenAddress == address(0)){
            require(deposit_ledger[msg.sender].eth_amount >= amount);
            deposit_ledger[msg.sender].eth_amount -= amount;
            msg.sender.call{value: amount}("");
        }
        else{
            require(deposit_ledger[msg.sender].usdc_amount >= amount);
            deposit_ledger[msg.sender].usdc_amount -= amount;
            usdc.transfer(msg.sender, amount);
        }
    }

    function usdc_update() public {
        usdc_amount = usdc.balanceOf(address(this));
    }

    function getAccruedSupplyAmount(address _addr) external payable returns (uint256) {

    }
}
