// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.4;

/**
 * IOperatorRegistry contract.
 * @author Yoel Zerbib
 * Date created: 4.6.22.
 * Github
**/

interface IOperatorRegistry {
    function isOperator(address _address) external view returns (bool);
}