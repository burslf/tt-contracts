// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.4;

contract PaymentHandler {

    event AmountReceived(address sender, uint value);

    mapping(uint => mapping(address => uint)) public shares;
    mapping(uint => mapping(address => bool)) public isPayee;
    mapping(uint => mapping(address => uint)) public released;
    
    mapping(uint => address[]) public payees;
    mapping(uint => uint) public eventRevenue;
    
    mapping(uint => uint) public totalShare;
    
    // Event ID to his creator address
    mapping(uint => address) public creatorOfEvent;

    modifier onlyCreator(uint _id) {
        require(msg.sender == creatorOfEvent[_id], "Caller is not the creator");
        _;
    }

    function addPayee(uint _id, address _payee, uint _share) public onlyCreator(_id) {
        require(!isPayee[_id][_payee], "Payee already exist");
        require(totalShare[_id] + _share <= 100, "Share must not exeed 100%");

        isPayee[_id][_payee] = true;
        shares[_id][_payee] = _share;
        payees[_id].push(_payee);
        totalShare[_id] += _share;
    }

    function addPayees(uint _id, address[] calldata _payees, uint[] calldata _shares) public onlyCreator(_id) {
        require(_payees.length == _shares.length, "Error: Array size mismatched");

        for(uint i; i < _payees.length; i++) {
            addPayee(_id, _payees[i], _shares[i]);
        }
    }

    function getPayees(uint _id) public view returns(address[] memory, uint[] memory) {
        require(payees[_id].length > 0, "No payee found. Event doesn't exist or payees haven't been set");

        uint _length = payees[_id].length;

        uint[] memory allshares = new uint[](_length);

        for (uint i = 0; i < _length; i++) {
            allshares[i] = shares[_id][payees[_id][i]];
        } 

        return (payees[_id], allshares);
    }

    function releasable(uint _id, address _payee) public view returns(uint) {
        require(isPayee[_id][_payee], "Address is not payee");
        
        uint payeeRevenue = eventRevenue[_id] * shares[_id][_payee] / 100;
        uint payeeReleased = released[_id][_payee];
        
        return payeeRevenue - payeeReleased;
    }

    function release(uint _id, address _payee) public {
        require(isPayee[_id][msg.sender] || msg.sender == creatorOfEvent[_id], "You are not a payee nor the owner of the event");
        require(releasable(_id, _payee) > 0, "No funds to withdraw");

        uint amount = releasable(_id, _payee);
        (bool sent, ) = (_payee).call{value: amount}("");
        require(sent, "Oops, widthdrawal failed !");

        released[_id][_payee] += amount;
    }

    // fallback() external payable {
    //     if(msg.value > 0) {
    //         emit AmountReceived(msg.sender, msg.value);
    //     }
    // }
}

