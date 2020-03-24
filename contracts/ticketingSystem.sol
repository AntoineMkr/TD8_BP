pragma solidity >=0.5.0;

contract ticketingSystem{

    // VARIABLES AND STRUCTS

    //An artist as a name, a category and has an address
    struct artist {
        bytes32 name;
        uint artistCategory;
        address owner;
        uint totalTicketSold;

    }

    struct venue {
		bytes32 name;
		uint capacity;
		uint standardComission;
		address payable owner;
	}

	struct concert {
		uint artistId;
		uint venueId;
		uint concertDate;
		uint ticketPrice;

        //not declared by user
        bool validatedByArtist;
		bool validatedByVenue;
		uint totalSoldTicket;
		uint totalMoneyCollected;
	}
    struct ticket {
		uint concertId;
        address payable owner;

		bool isAvailable;
        bool isAvailableForSale;

        uint amountPaid;
	}

    //Counts number of artists created
    uint public artistCount = 0;
    //Counts the number of venues
    uint public venueCount = 0;
    //Counts the number of concerts
    uint public concertCount = 0;

    uint public ticketCount = 0;

    //MAPPINGS & ARRAYS
    mapping(uint => artist) public artistsRegister;
    mapping(bytes32=> uint) private artistsID;

    mapping(uint => venue) public venuesRegister;
    mapping(bytes32 => uint) public venuesID;

    mapping(uint => concert) public concertsRegister;

    mapping(uint => ticket) public ticketsRegister;

    //EVENTS
    event createdArtist(bytes32 name, uint id);
    event modifiedArtist(bytes32 name, uint id, address sender);
    event createdVenue(bytes32 name, uint id);
    event modifiedVenue(bytes32 name, uint id);
    event createdConcert(uint concertDate, bytes32 name, uint id);


    constructor() public {
    }

    //FUNCTIONS TEST 1 -- ARTISTS

    function createArtist(bytes32 _name, uint _artistCategory) public{
        artist memory newArtist = artist(_name,_artistCategory, msg.sender,0);
        artistCount++;
        artistsRegister[artistCount] = newArtist;
        artistsID[_name] = artistCount;
        emit createdArtist(_name,artistCount);
    }

    function getArtistId(bytes32 _name) public view returns(uint ID){
        return artistsID[_name];
    }

    function modifyArtist(uint _artistId, bytes32 _name, uint _artistCategory, address payable _newOwner) public{
        require(_name != 0x00, "not a valid name");
        require(artistsRegister[_artistId].owner == msg.sender, "not the artist");
        artistsRegister[_artistId].name = _name;
        artistsRegister[_artistId].artistCategory = _artistCategory;
        artistsRegister[_artistId].owner = _newOwner;
        emit modifiedArtist(_name,_artistId, msg.sender);
    }

    //FUNCTIONS TEST 2 -- VENUES
    function createVenue(bytes32 _name, uint _capacity, uint _standardComission) public{
        venue memory newVenue = venue(_name,_capacity,_standardComission, msg.sender);
        venueCount++;
        venuesRegister[venueCount] = newVenue;
        venuesID[_name] = venueCount;
        emit createdVenue(_name,venueCount);
    }
    function getVenueId(bytes32 _name) public view returns(uint ID){
        return venuesID[_name];
    }

    function modifyVenue(uint _venueId, bytes32 _name, uint _capacity, uint _standardComission, address payable _newOwner) public{
        require(_name != 0x00, "not a valid name");
        require(venuesRegister[_venueId].owner == msg.sender, "not the value owner");

        venuesRegister[_venueId].name = _name;
        venuesRegister[_venueId].capacity = _capacity;
        venuesRegister[_venueId].standardComission = _standardComission;
        venuesRegister[_venueId].owner = _newOwner;
        emit modifiedVenue(_name,_venueId);
    }

    //FUNCTIONS TEST 3 -- CONCERTS
    function createConcert(uint _artistId, uint _venueId, uint _concertDate, uint _ticketPrice) public {
        concert memory newConcert = concert(_artistId,_venueId,_concertDate, _ticketPrice, false,false,0,0);
        concertCount++;
        //Check if the concert's creator is an artist
        //if true the concert is validated
        if(msg.sender == artistsRegister[_artistId].owner){
            newConcert.validatedByArtist = true;
        }
        //Same for the venue
        if(msg.sender == venuesRegister[_venueId].owner){
            newConcert.validatedByVenue = true;
        }
        //No tickets have been sold yet so we set the values to 0

        concertsRegister[concertCount] = newConcert;
        emit createdConcert(_concertDate,artistsRegister[_artistId].name,concertCount);
    }

    function validateConcert(uint _concertId) public {
        concertsRegister[_concertId].validatedByVenue = true;
        concertsRegister[_concertId].validatedByArtist = true;
    }

    //Creation of a ticket, only artists can create tickets
    function emitTicket(uint _concertId, address payable _ticketOwner) public{
        // in the test 3: "Trying to emit tickets with another account, should fail"
        require(msg.sender == artistsRegister[1].owner);
        ticket memory newTicket = ticket(_concertId, _ticketOwner, true, true, 0);
        ticketCount++;
        ticketsRegister[ticketCount] = newTicket;
        concertsRegister[_concertId].totalSoldTicket++;
    }

    function useTicket(uint _ticketId) public {
        //should be the owner
        require(msg.sender == ticketsRegister[_ticketId].owner,"sender should be the owner");
        //SHould be the d day,     oneWeek = 60*60*24 so should be <= 60*60*24
        require(now > (concertsRegister[ticketsRegister[_ticketId].concertId].concertDate - 60*60*24), "should be used the d-day");
        //Should be validated by the venue
        require(concertsRegister[ticketsRegister[_ticketId].concertId].validatedByVenue == true,"sender should be the owner");

        //switching the ticket parameters to "used"
        ticketsRegister[_ticketId].isAvailable = false;
        ticketsRegister[_ticketId].owner = 0x0000000000000000000000000000000000000000;
    }

    //FUNCTIONS TEST 4 -- BUY/TRANSFER
    function buyTicket(uint _concertId) public payable{
        //need enough money
        require(concertsRegister[_concertId].ticketPrice <= msg.value, "not enough funds");

        ticketCount++;
        ticket memory tmp = ticket(_concertId, msg.sender,true,false,concertsRegister[_concertId].ticketPrice);
        ticketsRegister[ticketCount] = tmp;
        concertsRegister[_concertId].totalSoldTicket++;
        concertsRegister[_concertId].totalMoneyCollected += tmp.amountPaid;
        artistsRegister[concertsRegister[_concertId].artistId].totalTicketSold ++;
    }

    function transferTicket(uint _ticketId, address payable _newOwner) public{
        //Sender should be the owner
        require(ticketsRegister[_ticketId].owner==msg.sender, "not the ticket owner");
        ticketsRegister[_ticketId].owner = _newOwner;
    }

    //FUNCTIONS TEST 5 -- CONCERT CASHOUT
    function cashOutConcert(uint _concertId, address payable _cashOutAddress) public{
        //only the artist can cashout
        require(msg.sender == artistsRegister[concertsRegister[_concertId].artistId].owner,"should be the artist");
        //can cashout only after the concert
        require(now >= concertsRegister[_concertId].concertDate, "should be after the concert");

        //Some calculations, we split the revenues
        uint totalMoney = concertsRegister[_concertId].totalMoneyCollected;
        uint venueMoney = venuesRegister[concertsRegister[_concertId].venueId].standardComission;
        uint artistMoney = totalMoney - venueMoney;

        venuesRegister[concertsRegister[_concertId].venueId].owner.transfer(venueMoney);
        _cashOutAddress.transfer(artistMoney);
    }

    //FUNCTIONS TEST 6 -- TICKET SELLING
    function offerTicketForSale(uint _ticketId, uint _salePrice) public{
        require(msg.sender == ticketsRegister[_ticketId].owner, "should be the owner");
        //CANT SALE AT A HIGHER PRICE
        require(ticketsRegister[_ticketId].amountPaid > _salePrice,"should be cheaper");

        ticketsRegister[_ticketId].amountPaid = _salePrice;
        ticketsRegister[_ticketId].isAvailable = true;
        ticketsRegister[_ticketId].isAvailableForSale = true;

    }

    function buySecondHandTicket(uint _ticketId) public payable{
        //need enough money
        require(ticketsRegister[_ticketId].amountPaid <= msg.value, "not enough funds");
        require(ticketsRegister[_ticketId].isAvailable == true, "should be available");

        ticketsRegister[_ticketId].owner = msg.sender;
        //not available for sale anymore
        ticketsRegister[_ticketId].isAvailable = false;

    }










}
