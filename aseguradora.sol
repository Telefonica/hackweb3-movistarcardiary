// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

contract insuranceCompany is Operations{

        ERC20Basic private token;

        address Insurance; 
        address payable public insuranceCarrier; 
        address [] requestService;
        address [] InsuredAdress;
        string [] private nameServices;

        mapping (address => string) public Solicited_service;
        mapping (address => client) public MappingInsured;
        mapping (string => service) public MappingServices;
        mapping (address => ResultService) ResultServiceInvoice;
    

    constructor () public{
        token = new ERC20Basic(100);
        insuranceCarrier = msg.sender;
        Insurance = address(this);
        }
        
        struct service{
            string nameService;
            uint precioTokensServicio;
            bool EstateService;
        }

        struct client {
            address clientAdress;
            bool ClientAuthorization;
            address ContractAdress;
        }
        
        struct ResultService {
            string result_service;
            string codigo_IPFS;
        }

        event insuredCreated (address, address);
        event eventPurchased (uint256);
        event EventNewService(string, uint256);
        event evgiveService (address,string);
        event ununscribeService(string);
        
        modifier OnlyInsured(address _insuredAdress){
            require (MappingInsured[_insuredAdress].ClientAuthorization == true, "No estás autorizado para esa función. Solo los asegurados pueden acceder.");
            _;
        }
        
       
        modifier OnlyInsurance(address _insuranceAdress){
            require (insuranceCarrier == _insuranceAdress, "No estás autorizado para esa función. Solo las aseguradoras pueden acceder.");
            _;
        }

        modifier Insurance_or_Insured(address _insuredAdress, address _adressEntry){
            require ((MappingInsured[_adressEntry].ClientAuthorization == true 
                && _insuredAdress == _adressEntry) || insuranceCarrier == _adressEntry, 
                    "No estás autorizado para esa función. Solo los asegurados y aseguradoras pueden acceder.");
            _;
        }

        function createContractInsured() public {
            InsuredAdress.push(msg.sender);
            address addressInsured;
            addressInsured = address(new insuranceCar(msg.sender, token, Insurance, insuranceCarrier));
            MappingInsured[msg.sender] = client(msg.sender,true,addressInsured);
            emit insuredCreated(msg.sender,addressInsured);
        }
       
        function InsuredList() public view OnlyInsurance(msg.sender) returns(address [] memory){
        return InsuredAdress;
        }
        
        function newService(string memory _nameService, uint256 _costService) public OnlyInsurance(msg.sender){
            MappingServices[_nameService] = service(_nameService,_costService,true);
            nameServices.push(_nameService);
            emit EventNewService(_nameService,_costService);
        }
        
        function EstateOfService(string memory _nameService) public view returns (bool){
            return MappingServices[_nameService].EstateService;
        }


        function getCostService(string memory _nameService) public view returns (uint256 tokens){
            require(MappingServices[_nameService].EstateService == true, "Servicio no disponible");
            return MappingServices[_nameService].precioTokensServicio;
        }
       
        function ConsultServicesActives() public view returns (string [] memory) {
        string [] memory servicesActives =  new string[](nameServices.length);
        uint contador = 0;
        for (uint i = 0; i< nameServices.length; i++){
                if(EstateOfService(nameServices[i]) == true){
                    servicesActives[contador] = nameServices[i]; 
                    contador++;
                }
            }
            return servicesActives;
        }

        function giveService(address _insuredAdress, string memory _service) public OnlyInsured(_insuredAdress){
        require(MappingServices[_service].EstateService == true, "El servicio no esta activo");
        Solicited_service[_insuredAdress] = _service;
        requestService.push(_insuredAdress);
        emit evgiveService (_insuredAdress, _service);
        }
        function unsubscribeService(string memory _nameService) public OnlyInsurance(msg.sender){
            require(EstateOfService(_nameService) == true, "No se ha dado de alta el servicio.");
            MappingServices[_nameService].EstateService = false; 
            emit ununscribeService(_nameService);
        }
        
        function buyTokens(address _asegurado, uint _numTokens) public payable OnlyInsured(_asegurado) {
            uint256 Balance = balanceOf();
           require(_numTokens <= Balance, "Compra un numero de tokens adecuado");
            require(_numTokens > 0, "Compra un numero positivo de tokens");
            token.transfer(msg.sender, _numTokens);
            emit eventPurchased(_numTokens);
        }
        
        function addTokensbalance(uint _numTokens) public OnlyInsurance(msg.sender) {
            token.increaseTotalSuply(_numTokens);
        }
        
        function balanceOf() public view returns(uint256 tokens){
            return (token.balanceOf(address(this)));
        }

    function Invoice(address _insuredAdress, string memory _result, string memory _codigoIPFS) public OnlyInsurance(msg.sender){
       ResultServiceInvoice[_insuredAdress] = ResultService (_result, _codigoIPFS);
    }

    function seeInvoices(address _insuredAdress) public view returns (string memory _diagnostico, string memory _codigoIPFS) {
        _diagnostico = ResultServiceInvoice[_insuredAdress].result_service;
        _codigoIPFS = ResultServiceInvoice[_insuredAdress].codigo_IPFS;
    }
        function consultHistoryInsured(address _addressInsured, address _addressEntry) public view Insurance_or_Insured(_addressInsured, _addressEntry) returns(string memory){
            string memory history = "";
            address addressContractInsured = MappingInsured[_addressInsured].ContractAdress;
            for(uint i = 0; i < nameServices.length; i++){
                if(MappingServices[nameServices[i]].EstateService && insuranceCar(addressContractInsured).ServiceStatusInsured(nameServices[i]) == true){
                    (string memory nombreServicio,uint precioServicio) = insuranceCar(addressContractInsured).HistoryInsured(nameServices[i]);            
                    history = string(abi.encodePacked(history, "(", nombreServicio, ", ", uint2str(precioServicio), ") ------"));
                }
            }
            return history;
        }        
        
}

contract insuranceCar is Operations{
    
    constructor (address _owner , IERC20 _token, address _insurance , address payable _insuranceCarrier) public{
        owner.addressOwner = _owner;
        owner.tokens = _token;
        owner.estado = Estado.active;
        owner.insurance = _insurance;
        owner.insuranceCarrier = _insuranceCarrier;
    }
    
    enum  Estado {active,inactive}
    event paidService (address, string, uint256);
    event EventSelfDestruct(address);
    event eventPurchased (uint256);

    mapping (string => RequestedServices) historyInsured;

    Owner owner;
    RequestedServices services;

    struct RequestedServices{
        string nameService;
        uint256 costService;
        bool EstateService;
    }
   
    struct Owner{
        IERC20 tokens;
        address addressOwner;
        Estado estado;
        address insurance;
        address payable insuranceCarrier;
    }
    
    modifier  Only(address _direccion){
        require (_direccion == owner.addressOwner, "No eres un asegurado.");
        _;
    }
     function requestService(string memory _service) public  Only(msg.sender){
        require(insuranceCompany(owner.insurance).EstateOfService(_service) == true, "No esta dado de alta ese servicio.");
        uint256 payTokens = insuranceCompany(owner.insurance).getCostService(_service);
        require(payTokens <= balanceOf(), "Debes comprar más tokens para este servicio");
        owner.tokens.transfer(owner.insuranceCarrier, payTokens);
        historyInsured[_service] = RequestedServices(_service,payTokens,true);
        emit paidService (msg.sender, _service, payTokens);
    }

    function HistoryInsurerCarrier() public view  Only(msg.sender) returns(string memory) {
        return insuranceCompany(owner.insurance).consultHistoryInsured(msg.sender, msg.sender);
    }
    
    function HistoryInsured(string memory _service) public view returns (string memory nameService,uint costService){
        return (historyInsured[_service].nameService, historyInsured[ _service].costService);
    }

    function ServiceStatusInsured(string memory _nameService) public view returns (bool){
        return historyInsured[_nameService].EstateService;
    }

    function BuyTokens (uint _numTokens) payable public Only(msg.sender){
        require (_numTokens > 0, "Se tiene que comprar un númeor de tokens positivo.");
        uint coste = calculateCostTokens(_numTokens);
        require(msg.value >= coste, "No hay ethers suficientes. Añade más ethers o compra menos tokens");
        uint returnValue = msg.value - coste;
        msg.sender.transfer(returnValue);
        insuranceCompany(owner.insurance).buyTokens(msg.sender, _numTokens);
    }

    function balanceOf() public view  Only(msg.sender) returns (uint256 _balance) {
        return (owner.tokens.balanceOf(address(this)));
    }

    function ununscribe() public  Only(msg.sender){
        emit EventSelfDestruct(msg.sender);
        selfdestruct(msg.sender); 
    }

    
}