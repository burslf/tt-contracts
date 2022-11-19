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
    // Mappings
    
    // Event-Ticketing
        // Creator address to event offchain data
    mapping(address => mapping(uint => string)) eventOffchainData;
        // Creator address to event supply
    mapping(address => mapping(uint => uint)) eventSupply;
        // Creator address to event price
    mapping(address => mapping(uint => uint)) eventPrice;
        // Creator address to event date
    mapping(address => mapping(uint => uint)) eventDate;
        // Creator address to event grey market price
    mapping(address => mapping(uint => bool)) eventGreyMarketAllowed;

    // Event-Options
        // Creator address to event option fees
    mapping(address => mapping(uint => uint)) eventOptionFees;
        // Creator address to event total option count
    mapping(address => mapping(uint => uint)) eventOptionCount;

    // Options
        // Creator address to event option count for specific buyer
    mapping(address => mapping(uint => mapping(address => uint))) public eventOptionAmount;
        // Creator address to event option duration for specific buyer
    mapping(address => mapping(uint => mapping(address => uint))) public eventOptionTime;
        // Creator address to event address that is authorize to perform tx on this option
    mapping(address => mapping(uint => mapping(address => address))) public eventOptionAllowance;
    
    // General Mappings
        // Creator to his total revenue
    // mapping(address => uint) public ownerRevenue;
    
        // Creator to his total events
    mapping(address => uint) public totalCreatorEvents;

        // Event ID to his creator address
    mapping(uint => address) public creatorOfEvent;
        // Event ID to 
    mapping(uint => uint) public idOfEvent;

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
        string url,
        uint timestamp
    );
        // Emitted when new option is added to an event
    event OptionAdded(
        address indexed creator, 
        address indexed optionOwner,
        uint indexed eventId,
        uint amount,
        uint duration
    );
    // Emitted when new option is removed from an event
    event OptionRemoved(
        address indexed creator, 
        address indexed optionOwner,
        uint indexed eventId,
        uint amount
    );

    // Handle grey market price 
    modifier greyMaketHandler(uint _id, uint _amount) {
        address eventCreator = creatorOfEvent[_id];
        uint creatorEventId = idOfEvent[_id];
        require(eventGreyMarketAllowed[eventCreator][creatorEventId], "Grey market is disallowed for this event.");
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

        uint newEvent = totalCreatorEvents[msg.sender];

        // Add payees and their shares 
        addPayees(msg.sender, newEvent, _payees, _shares);

        // Update event data
        eventSupply[msg.sender][newEvent] = _eventSupply_Price_Date[0];
        eventPrice[msg.sender][newEvent] = _eventSupply_Price_Date[1];
        eventDate[msg.sender][newEvent] = _eventSupply_Price_Date[2];
        eventGreyMarketAllowed[msg.sender][newEvent] = _greyMarketAllowed;

        // If there is no custom fees, put base option fees
        if (_optionFees > 0) {
            eventOptionFees[msg.sender][newEvent] = _optionFees;
        }else{
            eventOptionFees[msg.sender][newEvent] = baseOptionFees;
        }


        // Update eventId to creator address mapping
        creatorOfEvent[newEvent] = msg.sender;
        idOfEvent[totalEvents] = newEvent;

        emit EventCreated(
            totalEvents, 
            msg.sender, 
            _eventSupply_Price_Date[0],
            _eventSupply_Price_Date[1],
            _eventSupply_Price_Date[2],
            _optionFees,
            _greyMarketAllowed
        );

        if (bytes(_offchainData).length > 0) {
            eventOffchainData[msg.sender][newEvent] = _offchainData;
            emit OffchainDataUpdated(totalEvents, _offchainData, block.timestamp);
        }

        totalCreatorEvents[msg.sender] += 1;
        totalEvents += 1;
    }


    function saveOffchainData(uint _id, string memory _offchainData) public {
        address eventCreator = creatorOfEvent[_id];

        require(eventCreator == msg.sender, "You are not the event creator");
        require(totalEvents >= _id, "Event doesn't exist");

        uint eventId = idOfEvent[_id];

        // Update IPFS data for this event
        eventOffchainData[msg.sender][eventId] = _offchainData;

        emit OffchainDataUpdated(_id, _offchainData, block.timestamp);
    }


    function mint(address _to, address _creator, uint _id, uint _amount, bytes memory _data) public payable {        
        require(totalCreatorEvents[_creator] >= _id, "Event doesn't exist");
        require(eventSupply[_creator][_id] >= _amount, "No supply for event");
        require(block.timestamp <= eventDate[_creator][_id], "Event date is passed");
        require(msg.value == (eventPrice[_creator][_id] * _amount), "Incorrect ETH amount");

        // Mint a new ticket for this event
        _mint(_to, _id, _amount, _data);

        // Update general event data
        eventSupply[_creator][_id] -= _amount;
        
        // Update PaymentHandler
        eventRevenue[_creator][_id] += msg.value;

    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public payable onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }


    function optionTicket(address _creator, uint _id, uint _amount, uint _optionDuration) public payable {   
        require(totalCreatorEvents[_creator] >= _id, "Event doesn't exist");

        // Timestamp for the option from the moment the user call the function
        uint optionTimestamp = block.timestamp + (60 * 60 * _optionDuration);
        require(optionTimestamp <= eventDate[_creator][_id], "Event date is passed");

        // Get option fee price for this event
        uint optionFees = eventOptionFees[_creator][_id];
        uint optionPrice = (eventPrice[_creator][_id] * optionFees * _optionDuration * _amount) / 100;
        
        require(msg.value >= optionPrice, "Not enough ETH");
        require(eventSupply[_creator][_id] >= _amount, "Amount would exceed ticket supply !");
        
        // Update option data for this event
        eventOptionAmount[_creator][_id][msg.sender] += _amount;
        eventOptionAllowance[_creator][_id][msg.sender] = msg.sender;
        eventOptionTime[_creator][_id][msg.sender] = optionTimestamp;
        eventOptionCount[_creator][_id] += _amount;
        
        // Update general event data
        eventSupply[_creator][_id] -= _amount;
        // ownerRevenue[_creator] += msg.value;

        emit OptionAdded(_creator, msg.sender, _id, _amount, optionTimestamp);
    }
    

    function removeOption(address _creator, uint _id, address _to, uint _amount) public {
        require(totalCreatorEvents[_creator] >= _id, "Event doesn't exist");
        require(eventOptionAllowance[_creator][_id][_to] == msg.sender || operatorsRegistry.isOperator(msg.sender), "Not allowed");
        require(eventOptionAmount[_creator][_id][_to] >= _amount, "No option to remove");
        require(block.timestamp < eventOptionTime[_creator][_id][_to], "Too late to remove the option");
        
        eventSupply[_creator][_id] += _amount;
        eventOptionAmount[_creator][_id][_to] -= _amount;
        eventOptionCount[_creator][_id] -= _amount;

        emit OptionRemoved(_creator, _to, _id, _amount);
    }


    function eventInfo(uint _id) public view returns(address _eventCreator, uint _eventDate, uint _eventPrice, uint _optionFees, uint _currentSupply, string memory _offchainData) {        
        address eventCreator = creatorOfEvent[_id];
        uint eventId = idOfEvent[_id];

        require(totalEvents >= _id, "Event doesn't exist");

        return (eventCreator, 
                eventDate[eventCreator][eventId], 
                eventPrice[eventCreator][eventId], 
                eventOptionFees[eventCreator][eventId], 
                eventSupply[eventCreator][eventId], 
                eventOffchainData[eventCreator][eventId]
        );
    }
    

    function ownerRevenue(address _creator) public view returns (uint) {
        require(totalCreatorEvents[_creator] > 0, "No event for this address");

        uint totalRevenue = 0;
        uint _totalCreatorEvents = totalCreatorEvents[_creator];
        
        for (uint i; i < _totalCreatorEvents; i++) {
            uint revenue = eventRevenue[_creator][i];
            totalRevenue += revenue;
        }

        return totalRevenue;
    }


    function uri(uint256 _id) public view override returns (string memory) {
        require(totalEvents >= _id, "NONEXISTENT_TOKEN");

        address creator = creatorOfEvent[_id];
        string memory tokenUri = eventOffchainData[creator][_id];
        
        return tokenUri;
    }

    function safeTransferFrom(
        address _from, 
        address _to, 
        uint256 _id, 
        uint256 _amount, 
        bytes memory _data
    ) 
        public override greyMaketHandler(_id, _amount)
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