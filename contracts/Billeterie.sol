// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.4;

/**
 * Ticketrust main contract.
 * @author Yoel Zerbib
 * Date created: 24.2.22.
 * Github
**/

import '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import './TicketrustMiddleware.sol';
import './PaymentHandler.sol';
import './utils/Strings.sol';


contract Billeterie is Initializable, ERC1155Upgradeable, TicketrustMiddleware, PaymentHandler, OwnableUpgradeable {
    // Global variables
    uint public totalEvents;
    uint public baseOptionFees;
    
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;


    /************
        Mappings 
     *************/
    
    // Event-Ticketing
        // Event ID to event offchain data
    mapping(uint => string) eventOffchainData;
        // Event ID to event supply
    mapping(uint => uint) eventSupply;
        // Event ID to event price
    mapping(uint => uint) eventPrice;
        // Event ID to event date
    mapping(uint => uint) eventDate;
        // Event ID to event grey market price
    mapping(uint => bool) eventGreyMarketAllowed;

    // Event-Options
        // Event ID to event option fees
    mapping(uint => uint) eventOptionFees;
        // Event ID to event total option count
    mapping(uint => uint) eventOptionCount;

    // Options
        // Event ID to event option count for specific buyer
    mapping(uint => mapping(address => uint)) public eventOptionAmount;
        // Event ID to event option duration for specific buyer
    mapping(uint => mapping(address => uint)) public eventOptionTime;
        // Event ID to event address that is authorize to perform tx on this option
    mapping(uint => mapping(address => address)) public eventOptionAllowance;
    
    // General Mappings
        // Creator to his total events
    mapping(address => uint) public creatorTotalEvents;

    // Contract URI
    string public s_contractURI;
    
    // Events
        // Emitted when new event is created
    event EventCreated(
        uint id, 
        address indexed owner,
        uint initialSupply,
        uint price,
        uint eventDate,
        uint optionFees,
        bool greyMarketAllowed
    );

        // Emitted when offchain data is updated
    event OffchainDataUpdated(
        uint indexed eventId,
        uint timestamp,
        string url
    );
        // Emitted when new option is added to an event
    event OptionAdded(
        address indexed optionOwner,
        uint indexed eventId,
        uint amount,
        uint duration
    );
    // Emitted when new option is removed from an event
    event OptionRemoved(
        address indexed optionOwner,
        uint indexed eventId,
        uint amount
    );

    // Handle grey market price 
    modifier greyMaketHandler(uint _id) {
        require(eventGreyMarketAllowed[_id], "Grey market is disallowed for this event.");
        _;
    }

    function initialize(address _committee, address _operatorsRegistry) public initializer {
        baseOptionFees = 4;
        name = "Bitetrus";
        symbol = "BTTT";
        setCommitteeAndOperators(_committee, _operatorsRegistry);
        __Ownable_init();
        __ERC1155_init("");
    }


    function createTicketing(
        uint[] calldata _eventSupply_Price_Date,
        bool _greyMarketAllowed,
        uint _optionFees, 
        string memory _offchainData,
        address[] calldata _payees,
        uint[] calldata _shares
    ) 
    public
    {
        require(_eventSupply_Price_Date.length == 3, "Mismatch in _eventSupply_Price_Date");

        uint newEventID = totalEvents;

        // Update eventId to creator address mapping
        creatorOfEvent[newEventID] = msg.sender;

        // Add payees and their shares 
        addPayees(newEventID, _payees, _shares);

        // Update event data
        eventSupply[newEventID] = _eventSupply_Price_Date[0];
        eventPrice[newEventID] = _eventSupply_Price_Date[1];
        eventDate[newEventID] = _eventSupply_Price_Date[2];
        eventGreyMarketAllowed[newEventID] = _greyMarketAllowed;

        // If there is no custom fees, put base option fees
        if (_optionFees > 0) {
            eventOptionFees[newEventID] = _optionFees;
        }else{
            eventOptionFees[newEventID] = baseOptionFees;
        }


        emit EventCreated(
            newEventID, 
            msg.sender, 
            _eventSupply_Price_Date[0],
            _eventSupply_Price_Date[1],
            _eventSupply_Price_Date[2],
            _optionFees,
            _greyMarketAllowed
        );

        if (bytes(_offchainData).length > 0) {
            eventOffchainData[newEventID] = _offchainData;
            emit OffchainDataUpdated(newEventID, block.timestamp, _offchainData);
        }

        creatorTotalEvents[msg.sender] += 1;
        totalEvents += 1;
    }


    function saveOffchainData(uint _id, string memory _offchainData) public onlyCreator(_id) {
        require(totalEvents >= _id, "Event doesn't exist");

        // Update IPFS data for this event
        eventOffchainData[_id] = _offchainData;

        emit OffchainDataUpdated(_id, block.timestamp, _offchainData);
    }


    function mint(address _to, uint _id, uint _amount, bytes memory _data) public payable {        
        require(_id < totalEvents, "Event doesn't exist");
        require(eventSupply[_id] >= _amount, "No supply for event");
        require(block.timestamp <= eventDate[_id], "Event date is passed");
        require(msg.value == (eventPrice[_id] * _amount), "Incorrect ETH amount");

        // Mint a new ticket for this event
        _mint(_to, _id, _amount, _data);

        // Update general event data
        eventSupply[_id] -= _amount;
        
        // Update PaymentHandler
        eventRevenue[_id] += msg.value;

    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public payable onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }


    function optionTicket(uint _id, uint _amount, uint _optionDuration) public payable {   
        require(_id < totalEvents, "Event doesn't exist");

        // Timestamp for the option from the moment the user call the function
        uint optionTimestamp = block.timestamp + (60 * 60 * _optionDuration);
        require(optionTimestamp <= eventDate[_id], "Event date is passed");

        // Get option fee price for this event
        uint optionFees = eventOptionFees[_id];
        uint optionPrice = (eventPrice[_id] * optionFees * _optionDuration * _amount) / 100;
        
        require(msg.value >= optionPrice, "Not enough ETH");
        require(eventSupply[_id] >= _amount, "Amount would exceed ticket supply !");
        
        // Update option data for this event
        eventOptionAmount[_id][msg.sender] += _amount;
        eventOptionAllowance[_id][msg.sender] = msg.sender;
        eventOptionTime[_id][msg.sender] = optionTimestamp;
        eventOptionCount[_id] += _amount;
        
        // Update general event data
        eventSupply[_id] -= _amount;
        // ownerRevenue += msg.value;

        emit OptionAdded(msg.sender, _id, _amount, optionTimestamp);
    }
    

    function removeOption(uint _id, address _to, uint _amount) public {
        require(_id < totalEvents, "Event doesn't exist");
        require(eventOptionAllowance[_id][_to] == msg.sender || operatorsRegistry.isOperator(msg.sender), "Not allowed");
        require(eventOptionAmount[_id][_to] >= _amount, "No option to remove");
        require(block.timestamp < eventOptionTime[_id][_to], "Too late to remove the option");
        
        eventSupply[_id] += _amount;
        eventOptionAmount[_id][_to] -= _amount;
        eventOptionCount[_id] -= _amount;

        emit OptionRemoved(_to, _id, _amount);
    }


    function eventInfo(uint _id) public view returns(address _eventCreator, uint _eventDate, uint _eventPrice, uint _optionFees, uint _currentSupply, string memory _offchainData) {        
        address eventCreator = creatorOfEvent[_id];
 
        require(totalEvents >= _id, "Event doesn't exist");

        return (eventCreator, 
                eventDate[_id], 
                eventPrice[_id], 
                eventOptionFees[_id], 
                eventSupply[_id], 
                eventOffchainData[_id]
        );
    }
    

    function ownerRevenue(address _creator) public view returns (uint) {
        require(creatorTotalEvents[_creator] > 0, "No event for this address");

        uint totalRevenue = 0;
        uint _creatorTotalEvents = creatorTotalEvents[_creator];
        
        for (uint i; i < _creatorTotalEvents; i++) {
            uint revenue = eventRevenue[i];
            totalRevenue += revenue;
        }

        return totalRevenue;
    }


    function uri(uint256 _id) public view override returns (string memory) {
        require(totalEvents >= _id, "NONEXISTENT_TOKEN");

        string memory tokenUri = eventOffchainData[_id];
        
        return tokenUri;
    }

    function safeTransferFrom(
        address _from, 
        address _to, 
        uint256 _id, 
        uint256 _amount, 
        bytes memory _data
    )
        public override greyMaketHandler(_id)
    {
        require(_from == _msgSender() || isApprovedForAll(_from, _msgSender()), "ERC1155: caller is not token owner nor approved");

        _safeTransferFrom(_from, _to, _id, _amount, _data);
    }

    function contractURI() public view returns (string memory) {
        return s_contractURI;
    }

    function setContractURI(string calldata _uri) public onlyCommittee {
        s_contractURI = _uri;
    }
    
}