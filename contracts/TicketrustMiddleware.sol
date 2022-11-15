// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.4;

/**
 * Ticketrust Middleware contract.
 * @author Yoel Zerbib
 * Date created: 4.6.22.
 * Github
**/

import '../interfaces/IOperators.sol';

contract TicketrustMiddleware {

    IOperatorRegistry public operatorsRegistry;
    address public committee;

    // Only operator modifier
    modifier onlyOperator {
        require(operatorsRegistry.isOperator(msg.sender), "Restricted only to operator");
        _;
    }

    // Only committee modifier
    modifier onlyCommittee {
        require(msg.sender == committee, "Restricted only to committee");
        _;
    }

    function setCommitteeAndOperators(address _committee, address _operatorsRegistry) internal {
        committee = _committee;
        operatorsRegistry = IOperatorRegistry(_operatorsRegistry);
    }

    function setOperatorsRegistry(address _operatorsRegistry) public onlyCommittee {
        operatorsRegistry = IOperatorRegistry(_operatorsRegistry);
    }

}
