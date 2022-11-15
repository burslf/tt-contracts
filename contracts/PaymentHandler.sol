// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.4;

contract PaymentHandler {

    event AmountReceived(address sender, uint value);

    mapping(address => mapping(uint => mapping(address => uint))) public shares;
    mapping(address => mapping(uint => mapping(address => bool))) public isPayee;
    mapping(address => mapping(uint => mapping(address => uint))) public released;
    
    mapping(address => mapping(uint => address[])) public payees;
    mapping(address => mapping(uint => uint)) public eventRevenue;
    
    mapping(address => mapping(uint => uint)) public totalShare;
    
    modifier onlyCreator(address _creator) {
        require(msg.sender == _creator, "Caller is not the creator");
        _;
    }

    function addPayee(address _creator, uint _id, address _payee, uint _share) public onlyCreator(_creator) {
        require(!isPayee[_creator][_id][_payee], "Payee already exist");
        require(totalShare[_creator][_id] + _share <= 100, "Share must not exeed 100%");

        isPayee[_creator][_id][_payee] = true;
        shares[_creator][_id][_payee] = _share;
        payees[_creator][_id].push(_payee);
        totalShare[_creator][_id] += _share;
    }

    function addPayees(address _creator, uint _id, address[] calldata _payees, uint[] calldata _shares) public onlyCreator(_creator) {
        require(_payees.length == _shares.length, "Error: Array size mismatched");

        for(uint i; i < _payees.length; i++) {
            addPayee(msg.sender, _id, _payees[i], _shares[i]);
        }
    }

    function releasable(address _creator, uint _id, address _payee) public view returns(uint) {
        require(isPayee[_creator][_id][_payee], "Address is not payee");
        
        uint payeeRevenue = eventRevenue[_creator][_id] * shares[_creator][_id][_payee] / 100;
        uint payeeReleased = released[_creator][_id][_payee];
        
        return payeeRevenue - payeeReleased;
    }

    function release(address _creator, uint _id, address _payee) public {
        require(isPayee[_creator][_id][msg.sender] || msg.sender == _creator, "You are not a payee nor the owner of the event");
        require(releasable(_creator, _id, _payee) > 0, "No funds to withdraw");

        uint amount = releasable(_creator, _id, _payee);
        (bool sent, ) = (_payee).call{value: amount}("");
        require(sent, "Oops, widthdrawal failed !");

        released[_creator][_id][_payee] += amount;
    }

    // fallback() external payable {
    //     if(msg.value > 0) {
    //         emit AmountReceived(msg.sender, msg.value);
    //     }
    // }
}

