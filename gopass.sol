// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";

contract GoPass {
    string chassisNumber; //ID per car
    uint32  plateNumber;
    string carModel;
    string carBrand;
    uint32 kilometers;
    uint8  numberOfLowPressureWheels;
    uint8  numberOfMechanicFailures;
    uint8  numberOfElecticFailures;
    uint8  numberOfOilLevelFailures;
    uint8  numberOfCollisions;
    uint lastITV;
    uint lastMaintenance;
    uint16 numberOfEvents;
    address NFTaddress;
    address Owner;

    constructor (string memory _chassisNumber, uint32  _plateNumber, string memory _carModel, string memory _carBrand) public {
        chassisNumber = _chassisNumber; //ID per car
        plateNumber = _plateNumber;
        carModel = _carModel;
        carBrand = _carBrand;
        Owner = msg.sender;
    }

    enum eventKind { LowPressureWheels, MechanicFailure, ElectricFailure, OilLevelFailure, Collision, Maintenance, ITV }

    struct carEvent {
        uint date;
        uint kms;
        eventKind eventType;
        string description;
        address oracleAddress;    
    }

    
    mapping(uint => carEvent) events;
    mapping (address => bool) isAuthorized;

    modifier verifyKilometer(uint _kilometers) {
        require(kilometers <= _kilometers);
        _;
        
    }

    modifier onlyOwner(){
        require(msg.sender == Owner);
        _;
    }

    // @dev An insurance company (NFT owner) can register data
    modifier onlyAuthorized(){
         require(
             IERC721(NFTaddress).balanceOf(msg.sender) > 0,
             "You do not have the necessary NFT."
         );
         _;
     }


    function addEvent(eventKind _eventType, string memory _desc) public {
        carEvent memory _event;
        _event.date = block.timestamp;
        _event.kms = kilometers;
        _event.eventType = _eventType;
        _event.description = _desc;
        _event.oracleAddress = msg.sender;
        events[numberOfEvents] = _event;
        numberOfEvents ++;
        if (_event.eventType == eventKind.MechanicFailure) {
            numberOfMechanicFailures++;
        }
        if (_event.eventType == eventKind.LowPressureWheels) {
            numberOfLowPressureWheels++;
        }
        if (_event.eventType == eventKind.ElectricFailure) {
            numberOfElecticFailures++;
        }
        if (_event.eventType == eventKind.OilLevelFailure) {
            numberOfOilLevelFailures++;
        }
        if (_event.eventType == eventKind.Collision) {
            numberOfCollisions++;
        }
        if (_event.eventType == eventKind.Maintenance) {
            lastMaintenance=_event.date;
        }
        if (_event.eventType == eventKind.ITV) {
            lastITV=_event.date;
        }
        
    }

    function updateKms(uint32 _kms) onlyOwner verifyKilometer(_kms) public {
        kilometers = _kms;
    }

    function seeEvents() external view returns(carEvent[] memory) {
        carEvent[] memory ret = new carEvent[](numberOfEvents);
        for (uint i=0; i<numberOfEvents; i++) {
            ret[i] = events[i];
        }
        return ret;
    }

   /* function seeLastEventByType(eventKind _eT) onlyAuthorized external view returns(carEvent memory) {
        for (int i=numberOfEvents-1; i>=0; i--) {
            if (events[i].eventType==_eT){
                return events[i];
            }
        }
        revert("Not found");
    }*/

    function changeCarOwner(address _newOwner) onlyOwner() external {
        require(_newOwner != msg.sender);
        Owner = _newOwner;
    }

}