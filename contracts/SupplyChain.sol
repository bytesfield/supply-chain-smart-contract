// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./utils/Strings.sol";

contract SupplyChain {
    using Strings for string;

    uint32 productId = 0;
    uint32 participantId = 0;
    uint32 ownerId = 0;

    struct product {
        string modelNumber;
        string partNumber;
        string serialNumber;
        address productOwner;
        uint32 cost;
        uint256 mfgTimestamp;
    }

    mapping(uint32 => product) public products;

    struct participant {
        string username;
        string password;
        string participantType;
        address participantAddress;
    }

    mapping(uint32 => participant) public participants;

    struct ownership {
        uint32 productId;
        uint32 ownerId;
        uint256 trxTimestamp;
        address productOwner;
    }

    mapping(uint32 => ownership) public ownerships; //Ownership ny Ownership Id => owner_id
    mapping(uint32 => uint32[]) public productTracker; //Ownership by product Id (productId) => Movement tracking

    event TransferOwnership(uint32 productId);

    struct ParticipantType {
        string manufacturer;
        string supplier;
        string consumer;
    }

    /**
     * Adds an address as a participant
     *
     * @param _username Participant Username
     * @param _password Participant Username
     * @param _participantType Participant Type
     * @param _participantAddress Participant ETH Address
     *
     * @return _userId
     */
    function addParticipant(
        string memory _username,
        string memory _password,
        string memory _participantType,
        address _participantAddress
    ) public returns (uint32 _userId) {
        uint32 userId = participantId++;

        participants[userId].username = _username;
        participants[userId].password = _password;
        participants[userId].participantType = _participantType;
        participants[userId].participantAddress = _participantAddress;

        return userId;
    }

    /**
     * Get a Participant
     *
     * @param _productId Participant Product Id
     *
     * @return (string memory,address, string memory)
     */
    function getParticipant(uint32 _productId)
        public
        view
        returns (
            string memory,
            address,
            string memory
        )
    {
        return (
            participants[_productId].username,
            participants[_productId].participantAddress,
            participants[_productId].participantType
        );
    }

    /**
     * Adds a product
     *
     * @param _ownerId Ownwer's Id
     * @param _modelNumber Product Model Number
     * @param _partNumber Product Part Number
     * @param _serialNumber Product Serial Number
     * @param _cost Product Cost
     *
     * @return __productId
     */
    function addProduct(
        uint32 _ownerId,
        string memory _modelNumber,
        string memory _partNumber,
        string memory _serialNumber,
        uint32 _cost
    ) public returns (uint32 __productId) {
        require(
            participants[_ownerId].participantType.compare("Manufacturer"),
            "Only Manufacturer can add products"
        );
        uint32 _productId = productId++;

        products[_productId].modelNumber = _modelNumber;
        products[_productId].partNumber = _partNumber;
        products[_productId].serialNumber = _serialNumber;
        products[_productId].productOwner = participants[_ownerId]
            .participantAddress;
        products[_productId].cost = _cost;
        products[_productId].mfgTimestamp = _currentTime();

        return _productId;
    }

    /**
     * Get a Product
     *
     * @param _productId Product Id
     *
     * @return product
     */
    function getProduct(uint32 _productId)
        public
        view
        returns (product memory)
    {
        return products[_productId];
    }

    modifier onlyOwner(uint32 _productId) {
        require(
            products[_productId].productOwner == msg.sender,
            "Restricted to only product owner"
        );
        _;
    }

    /**
     * Create a new owner of a product (Transfer Ownership)
     *
     * @param _userId1 First Participant Id
     * @param _userId2 Second Participant Id
     * @param _productId Product Id
     *
     * @return bool
     */
    function newOwner(
        uint32 _userId1,
        uint32 _userId2,
        uint32 _productId
    ) public onlyOwner(_productId) returns (bool) {
        participant memory firstParticipant = participants[_userId1];
        participant memory secondParticipant = participants[_userId2];
        uint32 _ownershipId = ownerId++;

        string memory manufacturer = "Manufacturer";
        string memory supplier = "Supplier";
        string memory consumer = "Consumer";

        if (
            firstParticipant.participantType.compare(manufacturer) &&
            secondParticipant.participantType.compare(supplier)
        ) {
            return
                _createOwnership(
                    _userId2,
                    _ownershipId,
                    _productId,
                    secondParticipant
                );
        } else if (
            firstParticipant.participantType.compare(supplier) &&
            secondParticipant.participantType.compare(supplier)
        ) {
            return
                _createOwnership(
                    _userId2,
                    _ownershipId,
                    _productId,
                    secondParticipant
                );
        } else if (
            firstParticipant.participantType.compare(supplier) &&
            secondParticipant.participantType.compare(consumer)
        ) {
            return
                _createOwnership(
                    _userId2,
                    _ownershipId,
                    _productId,
                    secondParticipant
                );
        }

        return false;
    }

    function _currentTime() internal view returns (uint256) {
        return block.timestamp;
    }

    /**
     * Create a new owner of a product (Transfer Ownership)
     *
     * @param _ownerId Owner Id
     * @param _ownershipId Ownership Id
     * @param _productId Product Id
     * @param _participant Participant
     *
     * @return bool
     */
    function _createOwnership(
        uint32 _ownerId,
        uint32 _ownershipId,
        uint32 _productId,
        participant memory _participant
    ) private returns (bool) {
        ownerships[_ownershipId].productId = _productId;
        ownerships[_ownershipId].ownerId = _ownerId;
        ownerships[_ownershipId].trxTimestamp = _currentTime();
        ownerships[_ownershipId].productOwner = _participant.participantAddress;
        productTracker[_productId].push(_ownershipId);

        emit TransferOwnership(_productId);

        return true;
    }

    /**
     * Get Product Provenance
     *
     * @param _productId Product Id
     *
     * @return uint32[]
     */
    function getProvenance(uint32 _productId)
        external
        view
        returns (uint32[] memory)
    {
        return productTracker[_productId];
    }

    /**
     * Get Ownership
     *
     * @param _ownershipId Ownership Id
     *
     * @return ownership
     */
    function getOwnership(uint32 _ownershipId)
        external
        view
        returns (ownership memory)
    {
        return ownerships[_ownershipId];
    }

    /**
     * Authenticate a Participant
     *
     * @param _userId Participant Id
     * @param _username Participant Username
     * @param _userType Participant Type
     * @param _password Participant Username
     *
     * @return bool
     */
    function authParticipant(
        uint32 _userId,
        string memory _username,
        string memory _userType,
        string memory _password
    ) external view returns (bool) {
        if (participants[_userId].participantType.compare(_userType)) {
            if (participants[_userId].username.compare(_username)) {
                if (participants[_userId].password.compare(_password)) {
                    return (true);
                }
            }
        }
        return false;
    }

    function compare(string calldata _base, string calldata _value)
        public
        pure
        returns (bool)
    {
        //coverts strings to bytes 32 and pass it to the keccak256 hash algorithm and compare the results
        return
            keccak256(abi.encodePacked(_base)) ==
            keccak256(abi.encodePacked(_value));
    }
}
