// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract IPriceOracle {
    constructor(address dream, address _usdc) {
    }
}

contract DreamAcademyLending is ERC20{
    uint256 public number;
    ERC20 usdc;

    mapping (address => uint256) loan_ledger;
    mapping (address => mapping (address => uint256)) deposit_ledger;

    constructor(address _oracle, address _usdc) {
        usdc = ERC20(_usdc);
    }
    function deposit(address tokenAddress, uint256 amount) external{
        require(tokenAddress != address(0));
        if(tokenAddress == address(usdc)){
            usdc.transferFrom(msg.sender, address(this), amount);
            deposit_ledger[msg.sender][tokenAddress] += amount;
        }
        else{
            ERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
            deposit_ledger[msg.sender][tokenAddress] += amount;

        }

    }
    function borrow(address tokenAddress, uint256 amount) external {
        require(tokenAddress == address(usdc));
        require(usdc.balanceOf(address(this)) >= amount);
        ERC20(tokenAddress).transfer(msg.sender, amount);
        loan_ledger[msg.sender] += amount;

    }
    function repay(address tokenAddress, uint256 amount) external {
        require(loan_ledger[msg.sender] <= amount);
        ERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        loan_ledger[msg.sender] -= amount;
    }
    function liquidate(address user, address tokenAddress, uint256 amount) external {

    }
    function withdraw(address tokenAddress, uint256 amount) external {
        require(deposit_ledger[msg.sender][tokenAddress] >= amount);
        ERC20(tokenAddress).transfer(msg.sender, amount);
        deposit_ledger[msg.sender][tokenAddress] -= amount;
    }

}
