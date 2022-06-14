pragma solidity ^0.6.12;
//SPDX-License-Identifier: Unlicensed

//library contracts
import "./libraries/IERC20.sol";
import "./libraries/Context.sol";
import "./libraries/Ownable.sol";

//chain link
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract NftRaffleWorld is Ownable, VRFConsumerBase {
    event SetRequiredRaffleLink(
        address indexed user,
        uint256 _requireRaffleLink
    );
    event AddRaffle(
        address indexed user,
        address _tokenContract,
        uint256 _ticketPrice,
        uint256 _ticketsNumber,
        string _raffleType,
        uint256 _raffleStartDate,
        uint256 _lockDays,
        string _raffleName
    );

    event SetRaffleDiscountLevels(
        address indexed user,
        uint256 indexed _raffleId,
        uint256 _ticketsNo,
        uint256 discountPercentage
    );
    event SetRaffleCanceledStatus(
        address indexed user,
        uint256 indexed _raffleId,
        bool _canceled
    );
    event Winner(
        uint256 indexed _raffleId,
        address indexed winner,
        address _collectionAddress,
        uint256 _nftId
    );

    modifier beforeRaffleStart(uint256 _raffleId) {
        require(
            block.timestamp < raffles[_raffleId].raffleStartDate,
            "You cannot update raffle params after it started!"
        );
        _;
    }

    modifier checkTicketsAcquisition(uint256 _raffleId, uint256 _ticketsNo) {
        require(raffles[_raffleId].canceled == false, "Raffle is canceled!");
        require(
            keccak256(bytes(raffles[_raffleId].status)) !=
                keccak256(bytes("ended")),
            "Raffle has ended!"
        );
        require(
            raffleEntries[_raffleId].length.add(_ticketsNo) <=
                raffles[_raffleId].ticketsNumber,
            "You need to buy less tickets!"
        );
        require(
            raffles[_raffleId].raffleStartDate < block.timestamp,
            "Raffle has not started yet!"
        );
        _;
    }

    struct DiscountLevel {
        uint256 ticketsNumber;
        uint256 discountPercentage;
    }

    struct WinnerStructure {
        address winnerAddress;
        address nftAddress;
        uint256 nftId;
    }

    struct RaffleRefferals {
        uint256 bronze;
        uint256 silver;
        uint256 gold;
        uint256 diamond;
        uint256 totalRefferals;
        uint256 ticketsGivenByAdmin;
    }

    struct RaffleRandom {
        uint256 raffleId;
        uint256 random;
    }

    struct RaffleEntry {
        address buyer;
        uint256 buy_time;
    }

    struct RaffleIndices {
        uint256 raffles_index;
        uint256 active_raffles_index;
        uint256 raffles_by_type_index;
        uint256 active_raffles_by_type_index;
    }

    struct Partner {
        string partnerName;
        address partnerAddress;
        uint256 partnerAmount;
    }

    mapping(uint256 => DiscountLevel[]) public discountLevels;
    mapping(uint256 => WinnerStructure[]) public winnerStructure;
    mapping(uint256 => RaffleEntry[]) public raffleEntries;
    mapping(address => mapping(uint256 => uint256[]))
        public raffleEntriesPositionById;
    mapping(address => RaffleRefferals) public refferals;
    mapping(bytes32 => RaffleRandom) public randomRequests;
    mapping(uint256 => RaffleIndices) public rafflesIndices;
    mapping(uint256 => Partner) public rafflesPartners;

    struct Raffle {
        address tokenContract;
        uint256 ticketPrice;
        uint256 ticketsNumber;
        string raffleType;
        uint256 raffleStartDate;
        uint256 lockDays;
        string raffleName;
        bool canceled;
        string status;
    }

    uint256 public requiredRaffleLink = 0;
    uint256 public activeRaffles = 0;
    uint256 public rafflesNumber = 0;
    Raffle[] public raffles;
    uint256[] public active_raffles;
    uint256[] public bronze_raffles;
    uint256[] public active_bronze_raffles;
    uint256[] public silver_raffles;
    uint256[] public active_silver_raffles;
    uint256[] public gold_raffles;
    uint256[] public active_gold_raffles;
    uint256[] public diamond_raffles;
    uint256[] public active_diamond_raffles;

    address private immutable linkTokenContractAddress;
    IERC20 private immutable linkToken;

    address private immutable vrfCoordinatorAddress;

    bytes32 private keyHash;
    uint256 public randomResult;

    constructor(
        bytes32 _keyHash,
        address _vrfCoordinatorAddress,
        address _linkTokenContractAddress,
        uint256 _requiredRaffleLink
    )
        public
        VRFConsumerBase(_vrfCoordinatorAddress, _linkTokenContractAddress)
    {
        keyHash = _keyHash;
        linkTokenContractAddress = _linkTokenContractAddress;
        linkToken = IERC20(_linkTokenContractAddress);
        vrfCoordinatorAddress = _vrfCoordinatorAddress;
        requiredRaffleLink = _requiredRaffleLink;
    }

    function _receiveFunds(address _tokenAddress, uint256 _amount) internal {
        if (_tokenAddress == address(0)) {
            require(msg.value == _amount, "Not enough funds!");
        } else {
            IERC20 token = IERC20(_tokenAddress);
            require(
                token.allowance(_msgSender(), address(this)) >= _amount,
                "Not enough funds!"
            );
            token.transferFrom(_msgSender(), address(this), _amount);
        }
    }

    function _giveFunds(
        address _user,
        address _tokenAddress,
        uint256 _amount
    ) internal {
        if (_tokenAddress == address(0)) {
            payable(_user).transfer(_amount);
        } else {
            IERC20 token = IERC20(_tokenAddress);
            token.transfer(_user, _amount);
        }
    }

    /*
        Check if raffle type is valid and raffle start date is in future 
    */
    function _checkRaffleParams(
        string memory _raffleType,
        uint256 _raffleStartDate
    ) internal view returns (bool) {
        bool raffleTypeValidity = false;
        if (keccak256(bytes(_raffleType)) == keccak256(bytes("bronze")))
            raffleTypeValidity = true;
        else if (keccak256(bytes(_raffleType)) == keccak256(bytes("silver")))
            raffleTypeValidity = true;
        else if (keccak256(bytes(_raffleType)) == keccak256(bytes("gold")))
            raffleTypeValidity = true;
        else if (keccak256(bytes(_raffleType)) == keccak256(bytes("diamond")))
            raffleTypeValidity = true;
        bool raffleStartDayValidity = false;
        if (_raffleStartDate >= block.timestamp) raffleStartDayValidity = true;
        return raffleTypeValidity && raffleStartDayValidity;
    }

    /*
        Add a raffle to the coresponding array 
    */
    function addRaffle(
        address _tokenContract,
        uint256 _ticketPrice,
        uint256 _ticketsNumber,
        string memory _raffleType,
        uint256 _raffleStartDate,
        uint256 _lockDays,
        string memory _raffleName
    ) external onlyOwner {
        //check if raffle type and raffle start date are valid
        require(
            _checkRaffleParams(_raffleType, _raffleStartDate) == true,
            "Raffle type or start date wrong!"
        );

        //check if the contract has enough link tokens to add the raffle

        uint256 requiredLinkAmount = activeRaffles.add(1).mul(
            requiredRaffleLink
        );
        require(
            requiredLinkAmount <= linkToken.balanceOf(address(this)),
            "Not enough LINK Tokens to add raffle!"
        );
        rafflesNumber = rafflesNumber.add(1);
        //add raffle to the main array
        raffles.push(
            Raffle({
                tokenContract: _tokenContract,
                ticketPrice: _ticketPrice,
                ticketsNumber: _ticketsNumber,
                raffleType: _raffleType,
                raffleStartDate: _raffleStartDate,
                lockDays: _lockDays,
                raffleName: _raffleName,
                canceled: false,
                status: "ongoing"
            })
        );

        //activate the raffle
        _activateRaffle(raffles.length - 1);

        rafflesIndices[raffles.length - 1].raffles_index = raffles.length - 1;

        //add the raffle to the coresponding array and set the index
        if (
            keccak256(bytes(raffles[raffles.length - 1].raffleType)) ==
            keccak256(bytes("bronze"))
        ) {
            bronze_raffles.push(raffles.length - 1);
            rafflesIndices[raffles.length - 1].raffles_by_type_index =
                bronze_raffles.length -
                1;
        } else if (
            keccak256(bytes(raffles[raffles.length - 1].raffleType)) ==
            keccak256(bytes("silver"))
        ) {
            silver_raffles.push(raffles.length - 1);
            rafflesIndices[raffles.length - 1].raffles_by_type_index =
                silver_raffles.length -
                1;
        } else if (
            keccak256(bytes(raffles[raffles.length - 1].raffleType)) ==
            keccak256(bytes("gold"))
        ) {
            gold_raffles.push(raffles.length - 1);
            rafflesIndices[raffles.length - 1].raffles_by_type_index =
                gold_raffles.length -
                1;
        } else {
            diamond_raffles.push(raffles.length - 1);
            rafflesIndices[raffles.length - 1].raffles_by_type_index =
                diamond_raffles.length -
                1;
        }

        emit AddRaffle(
            _msgSender(),
            _tokenContract,
            _ticketPrice,
            _ticketsNumber,
            _raffleType,
            _raffleStartDate,
            _lockDays,
            _raffleName
        );
    }

    /*
        set the canceled status to false and add the raffle to the coresponding arrays
    */
    function _activateRaffle(uint256 _raffleId) internal {
        raffles[_raffleId].canceled = false;

        //increment the active raf
        activeRaffles = activeRaffles.add(1);
        active_raffles.push(_raffleId);
        rafflesIndices[_raffleId].active_raffles_index =
            active_raffles.length -
            1;

        if (
            keccak256(bytes(raffles[_raffleId].raffleType)) ==
            keccak256(bytes("bronze"))
        ) {
            active_bronze_raffles.push(_raffleId);
            rafflesIndices[_raffleId].active_raffles_by_type_index =
                active_bronze_raffles.length -
                1;
        } else if (
            keccak256(bytes(raffles[_raffleId].raffleType)) ==
            keccak256(bytes("silver"))
        ) {
            active_silver_raffles.push(_raffleId);
            rafflesIndices[_raffleId].active_raffles_by_type_index =
                active_silver_raffles.length -
                1;
        } else if (
            keccak256(bytes(raffles[_raffleId].raffleType)) ==
            keccak256(bytes("gold"))
        ) {
            active_gold_raffles.push(_raffleId);
            rafflesIndices[_raffleId].active_raffles_by_type_index =
                active_gold_raffles.length -
                1;
        } else {
            active_diamond_raffles.push(_raffleId);
            rafflesIndices[_raffleId].active_raffles_by_type_index =
                active_diamond_raffles.length -
                1;
        }
    }

    /*
        set the canceled status to true and removes the raffle from the coresponding arrays
    */
    function _cancelRaffle(uint256 _raffleId) internal {
        raffles[_raffleId].canceled = true;

        active_raffles[
            rafflesIndices[_raffleId].active_raffles_index
        ] = active_raffles[
            rafflesIndices[active_raffles[active_raffles.length - 1]]
                .active_raffles_index
        ];
        rafflesIndices[active_raffles[active_raffles.length - 1]]
            .active_raffles_index = rafflesIndices[_raffleId]
            .active_raffles_index;
        rafflesIndices[_raffleId].active_raffles_index = uint256(-1);

        activeRaffles = activeRaffles.sub(1);
        active_raffles.pop();

        if (
            keccak256(bytes(raffles[_raffleId].raffleType)) ==
            keccak256(bytes("bronze"))
        ) {
            active_bronze_raffles[
                rafflesIndices[_raffleId].active_raffles_by_type_index
            ] = active_bronze_raffles[active_bronze_raffles.length - 1];
            rafflesIndices[
                active_bronze_raffles[active_bronze_raffles.length - 1]
            ].active_raffles_by_type_index = rafflesIndices[_raffleId]
                .active_raffles_by_type_index;

            rafflesIndices[_raffleId].active_raffles_by_type_index = uint256(
                -1
            );
            active_bronze_raffles.pop();
        } else if (
            keccak256(bytes(raffles[_raffleId].raffleType)) ==
            keccak256(bytes("silver"))
        ) {
            active_silver_raffles[
                rafflesIndices[_raffleId].active_raffles_by_type_index
            ] = active_silver_raffles[active_silver_raffles.length - 1];
            rafflesIndices[
                active_silver_raffles[active_silver_raffles.length - 1]
            ].active_raffles_by_type_index = rafflesIndices[_raffleId]
                .active_raffles_by_type_index;

            rafflesIndices[_raffleId].active_raffles_by_type_index = uint256(
                -1
            );
            active_silver_raffles.pop();
        } else if (
            keccak256(bytes(raffles[_raffleId].raffleType)) ==
            keccak256(bytes("gold"))
        ) {
            active_gold_raffles[
                rafflesIndices[_raffleId].active_raffles_by_type_index
            ] = active_gold_raffles[active_gold_raffles.length - 1];
            rafflesIndices[active_gold_raffles[active_gold_raffles.length - 1]]
                .active_raffles_by_type_index = rafflesIndices[_raffleId]
                .active_raffles_by_type_index;

            rafflesIndices[_raffleId].active_raffles_by_type_index = uint256(
                -1
            );
            active_gold_raffles.pop();
        } else {
            active_diamond_raffles[
                rafflesIndices[_raffleId].active_raffles_by_type_index
            ] = active_diamond_raffles[active_diamond_raffles.length - 1];
            rafflesIndices[
                active_diamond_raffles[active_diamond_raffles.length - 1]
            ].active_raffles_by_type_index = rafflesIndices[_raffleId]
                .active_raffles_by_type_index;

            rafflesIndices[_raffleId].active_raffles_by_type_index = uint256(
                -1
            );
            active_diamond_raffles.pop();
        }
    }

    function setRafflePartner(
        uint256 _raffleId,
        string memory _partnerName,
        address _partnerAddress,
        uint256 _partnerAmount
    ) external
      beforeRaffleStart(_raffleId)
      onlyOwner
     {
        rafflesPartners[_raffleId].partnerName = _partnerName;
        rafflesPartners[_raffleId].partnerAddress = _partnerAddress;
        rafflesPartners[_raffleId].partnerAmount = _partnerAmount;
    }

    function setRequiredRaffleLink(uint256 _requiredRaffleLink)
        external
        onlyOwner
    {
        requiredRaffleLink = _requiredRaffleLink;
        emit SetRequiredRaffleLink(_msgSender(), _requiredRaffleLink);
    }

    function setRaffleName(uint256 _raffleId, string memory _name)
        external
        beforeRaffleStart(_raffleId)
        onlyOwner
    {
        raffles[_raffleId].raffleName = _name;
    }

    function setRaffleTicketPrice(uint256 _raffleId, uint256 _ticketPrice)
        external
        beforeRaffleStart(_raffleId)
        onlyOwner
    {
        require(_ticketPrice > 0, "Ticket price should be greater than 0!");
        raffles[_raffleId].ticketPrice = _ticketPrice;
    }

    function setRaffleTicketsNumber(uint256 _raffleId, uint256 _ticketsNumber)
        external
        beforeRaffleStart(_raffleId)
        onlyOwner
    {
        raffles[_raffleId].ticketsNumber = _ticketsNumber;
    }

    function setRaffleStartDate(uint256 _raffleId, uint256 _raffleStartDate)
        external
        beforeRaffleStart(_raffleId)
        onlyOwner
    {
        require(
            _raffleStartDate > block.timestamp,
            "Start date should be in the future!"
        );
        raffles[_raffleId].raffleStartDate = _raffleStartDate;
    }

    function setRaffleLockDays(uint256 _raffleId, uint256 _lockDays)
        external
        beforeRaffleStart(_raffleId)
        onlyOwner
    {
        raffles[_raffleId].lockDays = _lockDays;
    }

    function setRaffleDiscountLevels(
        uint256 _raffleId,
        uint256 _ticketsNo,
        uint256 _discountPercentage
    ) external onlyOwner {
        bool existed = false;
        for (uint256 i = 0; i < discountLevels[_raffleId].length; i++) {
            if (discountLevels[_raffleId][i].ticketsNumber == _ticketsNo) {
                if (_discountPercentage == 0) {
                    discountLevels[_raffleId][i] = discountLevels[_raffleId][
                        discountLevels[_raffleId].length.sub(1)
                    ];
                    discountLevels[_raffleId].pop();
                } else {
                    discountLevels[_raffleId][i]
                        .discountPercentage = _discountPercentage;
                }
                existed = true;
                break;
            }
        }
        if (existed == false) {
            discountLevels[_raffleId].push(
                DiscountLevel({
                    ticketsNumber: _ticketsNo,
                    discountPercentage: _discountPercentage
                })
            );
        }
        emit SetRaffleDiscountLevels(
            _msgSender(),
            _raffleId,
            _ticketsNo,
            _discountPercentage
        );
    }

    function setRaffleWinnerStructure(
        uint256 _raffleId,
        uint256 _index,
        address _nftAddress,
        uint256 _nftId
    ) external beforeRaffleStart(_raffleId) onlyOwner {
        if (_nftAddress == address(0x00)) {
            require(_index < winnerStructure[_raffleId].length);
            winnerStructure[_raffleId][_index] = winnerStructure[_raffleId][
                winnerStructure[_raffleId].length - 1
            ];
            winnerStructure[_raffleId].pop();
        } else {
            winnerStructure[_raffleId].push(
                WinnerStructure({
                    nftAddress: _nftAddress,
                    nftId: _nftId,
                    winnerAddress: address(0x00)
                })
            );
        }
    }

    function getRafflesLength(string memory _raffleType)
        public
        view
        returns (uint256)
    {
        if (keccak256(bytes(_raffleType)) == keccak256(bytes("bronze"))) {
            return bronze_raffles.length;
        } else if (
            keccak256(bytes(_raffleType)) == keccak256(bytes("silver"))
        ) {
            return silver_raffles.length;
        } else if (keccak256(bytes(_raffleType)) == keccak256(bytes("gold"))) {
            return gold_raffles.length;
        } else {
            require(
                keccak256(bytes(_raffleType)) == keccak256(bytes("diamond")),
                "RaffleWorld: incorrect raffle type!"
            );
            return diamond_raffles.length;
        }
    }

    function getActiveRafflesLength(string memory _raffleType)
        public
        view
        returns (uint256)
    {
        if (keccak256(bytes(_raffleType)) == keccak256(bytes("bronze"))) {
            return active_bronze_raffles.length;
        } else if (
            keccak256(bytes(_raffleType)) == keccak256(bytes("silver"))
        ) {
            return active_silver_raffles.length;
        } else if (keccak256(bytes(_raffleType)) == keccak256(bytes("gold"))) {
            return active_gold_raffles.length;
        } else {
            require(
                keccak256(bytes(_raffleType)) == keccak256(bytes("diamond")),
                "Incorrect raffle type!"
            );
            return active_diamond_raffles.length;
        }
    }

    function getWinnerStructure(uint256 _raffleIndex, uint256 _structureIndex)
        external
        view
        returns (
            address winnerAddress,
            address nftAddress,
            uint256 nftId
        )
    {
        return (
            winnerStructure[_raffleIndex][_structureIndex].winnerAddress,
            winnerStructure[_raffleIndex][_structureIndex].nftAddress,
            winnerStructure[_raffleIndex][_structureIndex].nftId
        );
    }

    function boughtRaffleTicketsByUser(address _user, uint256 _raffleId)
        external
        view
        returns (uint256)
    {
        return raffleEntriesPositionById[_user][_raffleId].length;
    }

    function boughtRaffleTickets(uint256 _raffleId)
        external
        view
        returns (uint256)
    {
        return raffleEntries[_raffleId].length;
    }

    function getPrizesNumber(uint256 _raffleId)
        external
        view
        returns (uint256)
    {
        return winnerStructure[_raffleId].length;
    }

    function _addRaffleWinner(
        uint256 _raffleId,
        uint256 _winIndex,
        uint256 _winnerIndex
    ) internal {
        address winner = raffleEntries[_raffleId][_winnerIndex].buyer;
        winnerStructure[_raffleId][_winIndex].winnerAddress = winner;
        emit Winner(
            _raffleId,
            winner,
            winnerStructure[_raffleId][_winIndex].nftAddress,
            winnerStructure[_raffleId][_winIndex].nftId
        );
    }

    function setRaffleCanceledStatus(uint256 _raffleId, bool _canceled)
        external
        onlyOwner
    {
        if (_canceled == true) _cancelRaffle(_raffleId);
        else _activateRaffle(_raffleId);
        emit SetRaffleCanceledStatus(_msgSender(), _raffleId, _canceled);
    }

    function _getTicketsValue(uint256 _raffleId, uint256 _ticketsNo)
        internal
        view
        returns (uint256)
    {
        uint256 discount = 0;
        for (uint256 i = 0; i < discountLevels[_raffleId].length; i++) {
            if (discountLevels[_raffleId][i].ticketsNumber <= _ticketsNo) {
                discount = discountLevels[_raffleId][i].discountPercentage;
            } else {
                break;
            }
        }
        if (discount == 0)
            return raffles[_raffleId].ticketPrice.mul(_ticketsNo);
        discount = raffles[_raffleId]
            .ticketPrice
            .mul(_ticketsNo)
            .mul(discount)
            .div(10000);
        return raffles[_raffleId].ticketPrice.mul(_ticketsNo) - discount;
    }

    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 _raffleId)
        public
        returns (bytes32 requestId)
    {
        require(
            raffleEntries[_raffleId].length == raffles[_raffleId].ticketsNumber,
            "RaffleWorld: not all tickets were bought!"
        );
        requestId = requestRandomness(keyHash, requiredRaffleLink);
        randomRequests[requestId] = RaffleRandom({
            raffleId: _raffleId,
            random: 0
        });
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResult = randomness;
        randomRequests[requestId].random = randomness;
        _decideRaffle(requestId);
    }

    function _decideRaffle(bytes32 _requestId) internal {
        //getting the number of digits that raffle entries has
        uint256 _raffleId = randomRequests[_requestId].raffleId;
        uint256 random = randomRequests[_requestId].random;
        uint256 entries = raffleEntries[_raffleId].length;
        raffles[_raffleId].status = "ended";
        if (entries != 0) {
            for (uint256 i = 0; i < winnerStructure[_raffleId].length; i++) {
                uint256 index = uint256(keccak256(abi.encode(random, i))).mod(
                    raffleEntries[_raffleId].length
                );
                _addRaffleWinner(_raffleId, i, index);
            }
            _giveFunds(
                rafflesPartners[_raffleId].partnerAddress,
                raffles[_raffleId].tokenContract,
                rafflesPartners[_raffleId].partnerAmount
            );
        }
    }

    function subscribeToRaffle(
        uint256 _raffleId,
        uint256 _ticketsNo,
        address _refferedBy
    ) external payable checkTicketsAcquisition(_raffleId, _ticketsNo) {
        uint256 ticketsValue = _getTicketsValue(_raffleId, _ticketsNo);
        _receiveFunds(raffles[_raffleId].tokenContract, ticketsValue);

        for (uint256 i = 0; i < _ticketsNo; i++) {
            raffleEntriesPositionById[_msgSender()][_raffleId].push(
                raffleEntries[_raffleId].length
            );
            raffleEntries[_raffleId].push(
                RaffleEntry({buyer: _msgSender(), buy_time: block.timestamp})
            );
        }

        if (_refferedBy != address(0) && _refferedBy != _msgSender()) {
            refferals[_refferedBy].totalRefferals = refferals[_refferedBy]
                .totalRefferals
                .add(_ticketsNo);
            if (
                keccak256(bytes(raffles[_raffleId].raffleType)) ==
                keccak256(bytes("bronze"))
            ) {
                refferals[_refferedBy].bronze = refferals[_refferedBy]
                    .bronze
                    .add(_ticketsNo);
            } else if (
                keccak256(bytes(raffles[_raffleId].raffleType)) ==
                keccak256(bytes("silver"))
            ) {
                refferals[_refferedBy].silver = refferals[_refferedBy]
                    .silver
                    .add(_ticketsNo);
            } else if (
                keccak256(bytes(raffles[_raffleId].raffleType)) ==
                keccak256(bytes("gold"))
            ) {
                refferals[_refferedBy].gold = refferals[_refferedBy].gold.add(
                    1
                );
            } else {
                refferals[_refferedBy].diamond = refferals[_refferedBy]
                    .diamond
                    .add(_ticketsNo);
            }
        }

        if (
            raffleEntries[_raffleId].length == raffles[_raffleId].ticketsNumber
        ) {
            getRandomNumber(_raffleId);
        }
    }

    function giveTickets(
        uint256 _raffleId,
        uint256 _ticketsNo,
        address _to
    ) external onlyOwner checkTicketsAcquisition(_raffleId, _ticketsNo) {
        for (uint256 i = 0; i < _ticketsNo; i++) {
            raffleEntriesPositionById[_to][_raffleId].push(
                raffleEntries[_raffleId].length
            );
            raffleEntries[_raffleId].push(
                RaffleEntry({buyer: _to, buy_time: block.timestamp})
            );
        }

        refferals[_to].ticketsGivenByAdmin = refferals[_to]
            .ticketsGivenByAdmin
            .add(_ticketsNo);

        if (
            raffleEntries[_raffleId].length == raffles[_raffleId].ticketsNumber
        ) {
            getRandomNumber(_raffleId);
        }
    }

    function _beforeWithdraw(uint256 _raffleId) internal view returns (bool) {
        require(
            raffleEntriesPositionById[_msgSender()][_raffleId].length != 0,
            "You don't have any tickets!"
        );
        if (
            keccak256(bytes(raffles[_raffleId].status)) ==
            keccak256(bytes("ended"))
        ) return false;
        if (raffles[_raffleId].canceled == true) {
            return true;
        }
        uint256 length = raffleEntriesPositionById[_msgSender()][_raffleId]
            .length;
        uint256 time_of_last_subscribtion = raffleEntries[_raffleId][
            raffleEntriesPositionById[_msgSender()][_raffleId][length - 1]
        ].buy_time;
        if (
            time_of_last_subscribtion + raffles[_raffleId].lockDays <=
            block.timestamp
        ) {
            return true;
        }
        return false;
    }

    function withdrawSubscription(uint256 _raffleId) public {
        require(
            _beforeWithdraw(_raffleId),
            "You cannot withdraw your tickets!"
        );
        uint256 ticketsPrice = _getTicketsValue(
            _raffleId,
            raffleEntriesPositionById[_msgSender()][_raffleId].length
        );
        _giveFunds(
            _msgSender(),
            raffles[_raffleId].tokenContract,
            ticketsPrice.sub(ticketsPrice.div(10))
        );

        while (raffleEntriesPositionById[_msgSender()][_raffleId].length != 0) {
            uint256 sender_last_ticket_index = raffleEntriesPositionById[
                _msgSender()
            ][_raffleId][
                raffleEntriesPositionById[_msgSender()][_raffleId].length - 1
            ];
            raffleEntries[_raffleId][sender_last_ticket_index] = raffleEntries[
                _raffleId
            ][raffleEntries[_raffleId].length - 1];
            address last_guy = raffleEntries[_raffleId][
                raffleEntries[_raffleId].length - 1
            ].buyer;
            uint256 max = 0;
            uint256 pos = 0;
            if (sender_last_ticket_index < raffleEntries[_raffleId].length) {
                for (
                    uint256 i = 0;
                    i < raffleEntriesPositionById[last_guy][_raffleId].length;
                    i++
                ) {
                    if (
                        raffleEntriesPositionById[last_guy][_raffleId][i] > max
                    ) {
                        max = raffleEntriesPositionById[last_guy][_raffleId][i];
                        pos = i;
                    }
                }
                raffleEntriesPositionById[last_guy][_raffleId][
                    pos
                ] = sender_last_ticket_index;
            }
            raffleEntriesPositionById[_msgSender()][_raffleId].pop();
            raffleEntries[_raffleId].pop();
        }
    }

    function withdrawOwnerFunds(uint256 _raffleId, uint256 _amount)
        external
        onlyOwner
    {
        require(
            keccak256(bytes(raffles[_raffleId].status)) ==
                keccak256(bytes("ended"))
        );
        _giveFunds(owner(), raffles[_raffleId].tokenContract, _amount);
    }
}

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./vendor/SafeMathChainlink.sol";

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMathChainlink for uint256;

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee)
    internal returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) public {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}