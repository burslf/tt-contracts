// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.4;

/**
 * OperatorRegistry contract.
 * @author Yoel Zerbib
 * Date created: 4.6.22.
 * Github
**/

import "./utils/Array.sol";

contract OperatorsRegistry {

    using Array for address[];

    // Is operator mapping checker
    mapping(address => bool) public _isOperator;

    address [] public allOperators;

    address public committee;

    event OperatorStatusChanged(address operator, bool isMember);

    // Modifier for "only committee" methods 
    modifier onlyCommittee{
        require(msg.sender == committee, 'OperatorsRegistry: Restricted only to committee');
        _;
    }

    function initialize(address [] memory _operators, address _committee) public {
        // Register committee
        committee = _committee;

        // Operators initialization
        for(uint i = 0; i < _operators.length; i++) {
            addOperatorInternal(_operators[i]);
        }
    }

    function addOperator(address _address) public onlyCommittee {
        addOperatorInternal(_address);
    }

    function addOperatorInternal(address _address) internal {
        require(_isOperator[_address] == false, "OperatorsRegistry :: Address is already a operator");

        allOperators.push(_address);
        _isOperator[_address] = true;

        emit OperatorStatusChanged(_address, true);
    }

    function removeOperator(address _operator) external onlyCommittee {
        require(_isOperator[_operator] == true, "OperatorsRegistry :: Address is not a operator");

        uint length = allOperators.length;
        require(length > 1, "Cannot remove last operator.");

        // Use custom array library for removing from array
        allOperators.removeElement(_operator);
        _isOperator[_operator] = false;

        emit OperatorStatusChanged(_operator, false);
    }

}