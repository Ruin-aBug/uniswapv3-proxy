// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./libraries/TransferHelper.sol";

contract ERC20Approve{
    
    function approve(address token, address to, uint256 amount) external {
        TransferHelper.safeApprove(token, to, amount);
    }
    
    function allowance(address token,address owner, address to )external view returns(uint256){
        return IERC20(token).allowance(owner,to);
    }
}