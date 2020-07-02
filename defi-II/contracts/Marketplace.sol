pragma solidity >=0.4.22 <0.7.0;
// SPDX-License-Identifier: MIT

import "./../installed_contracts/zeppelin/contracts/math/SafeMath.sol";

contract Marketplace {
    
 using SafeMath for uint;
    
    struct User {
        uint reputation;
        string name;
        bool isUser;
    }

    struct Request {
            address company;
            uint id;
            uint deadline; //delai
            uint startTime;
            uint miniReputation;
            uint remuneration;
            string description;
            bytes32 url;
            State state;
            mapping(address=>bool) accepted;
            mapping(address=>bool) candidates;
    }

    address owner;
    mapping (address => uint) public balances;
    mapping(address => User) public users;
    mapping(uint => Request) public requests;
   // mapping(uint=>mapping(address=>bool))public candidates;
   

    uint public requestCount;
    uint decimal=100;
    uint cost=102;

    enum State{OPENED,ONGOING,CLOSED}

    event UserCreated(address _add,uint _reputation, string  _name, bool _isUser);
    event RequestCreated(address _add, uint _id, uint _deadline, uint _startTime,
    uint _miniReputation, uint _cost, string _description,
    string _url, State _state);
    event Application(uint _id,address _add,uint _reputation,bool _isCandidate);
    event OfferAccepted(uint _id,address _add,bool _isAccepted);
    event Delivration(uint _id,address _add,bytes32 _url,uint _reputation);

    constructor() public{
        owner = msg.sender;
        requestCount;
    }
   
   modifier requestState 
        (uint _id, State _state)
        {
            require(requests[_id].state==_state,"request is not accessible");
            _;
        }
    
    modifier nextRequestState
        (uint _id, State _state)
        {
            updateState(_id, _state);
         _;

        }
    
    modifier isUser
        (address _add)
        {
            require(_add!=address(0),"You are the 0 address");
            require(users[_add].isUser,"You are not a user !");
            _;
        }

    modifier isRequest
        (uint _id)
        {
            require(requests[_id].id > 0,"The request does not exist !");
            _;
        }
    
   
    modifier isCandidate
        (uint _id,address _add)
        {
            require(_add!=address(0),"You are the 0 address");
            require(requests[_id].candidates[_add],"You are not a candidate !");
            _;
        }

        
    modifier isCompany
        (uint _id)
        {
            require(msg.sender!=address(0),"You are the 0 address");
            require(requests[_id].company!=msg.sender,"You are the company !");
            _;
        }

    modifier isAccepted
        (uint _id,address _add)
        {
            require(_add!=address(0),"You are the 0 address");
            require(requests[_id].accepted[_add],"You are not accepted !");
            _;
        }
        
    modifier isInTime
    (uint _id)
    {
      require(requests[_id].startTime<=now && requests[_id].deadline>=now,"You are not in time");  
      _;
    }
    
    modifier afterDeadline
    (uint _id)
    {
        require(requests[_id].deadline < now,"The deadline is not reached !");
        _;
    }

    function  updateState(uint _id,State _state) internal{
        requests[_id].state = _state;
    }

//s'inscrire
    function inscription (string memory _name, uint _reputation) 
    public 
    {
        require(!users[msg.sender].isUser, "You are already user !");
        require(bytes(_name).length>0,"the name is not valid");
        require(_reputation>=1,"the reputation is not valid");
        User memory newUser = User(_reputation,_name,true);
        users[msg.sender] = newUser;
        emit UserCreated(msg.sender,_reputation,_name,true);
    }
    
    //ajouter demande
    function addRequest
    (string calldata _description,
    uint _miniReputation,
    uint _deadline,
    uint _remuneration)
    external
    payable
    isUser(msg.sender)
    {
        //verifier qu'on a bien une description 
        require(bytes(_description).length>0,"The description is not valid !");
        //verifier que la reputation est sup à 1
        require(_miniReputation>1,"miniReputation is not valid");
        //verifier que la durée est bien plus superieur à 0
        require(_deadline>0,"The deadline is not valid");
        //verifier que la remuneration est sup à 0
        require(_remuneration>0,"remuneration is not valid");
        //verifier si on a assez de Wei
        uint _amount = (_remuneration.mul(cost)).div(decimal);
        require(msg.value >= _amount,"not enough of Wei");
        requestCount++;
        balances [owner]=balances [owner].add(msg.value);
       uint deadline = _deadline * 1 days;
       Request memory newRequest = Request(msg.sender,requestCount,deadline,0,_miniReputation,_remuneration,_description,"",State.OPENED);
       requests[requestCount] = newRequest;
       emit RequestCreated(msg.sender,requestCount,deadline,0,requests[requestCount].miniReputation,requests[requestCount].remuneration,requests[requestCount].description,"",State.OPENED);
    }

    

//postuler
    function applyTo(uint _id)
    public
    isUser(msg.sender)
    isCompany(_id)
    isRequest(_id)
    requestState(_id,State.OPENED)
    {

        require(!requests[_id].candidates[msg.sender],"You are already candidate !");
        require(requests[_id].miniReputation<=users[msg.sender].reputation,"Reputation is not enought");
        requests[_id].candidates[msg.sender]=true;
        emit Application(_id,msg.sender,users[msg.sender].reputation,requests[_id].candidates[msg.sender]);
    }
    
    
//acceptOffer
    function acceptOffer(uint _id,address _add)
    public
    isRequest(_id)
    requestState (_id,State.OPENED)
    isCandidate(_id,_add)
    nextRequestState(_id,State.ONGOING)
    {
        require(requests[_id].company==msg.sender,"You are not the company !");
        requests[_id].startTime = now;
        requests[_id].deadline=requests[_id].deadline+requests[_id].startTime;
        requests[_id].accepted[_add] =true;   
         emit OfferAccepted(_id,_add,requests[_id].accepted[_add]);
    }
    
//delivery

    function delivery(uint _id,bytes32 _url)
    public
    isAccepted(_id,msg.sender)
    isRequest(_id)
    requestState (_id,State.ONGOING)
    isInTime(_id)
    nextRequestState(_id,State.CLOSED)
    {
        require(bytes32(_url).length>0,"The url is not valid !");
        requests[_id].url = _url;
        users[msg.sender].reputation++;
        uint remuneration = requests[_id].remuneration;
       // address company = requests[_id].company;
        balances[owner] = balances[owner].sub(remuneration);
        emit Delivration(_id,msg.sender,requests[_id].url,users[msg.sender].reputation++);
        msg.sender.transfer(remuneration);
    }
    
    
    function sanction(uint _id, address _add)
    public
    isAccepted(_id,_add)
    isRequest(_id)
    requestState (_id,State.ONGOING)
    afterDeadline(_id)
    nextRequestState(_id,State.CLOSED)
    {
        require(requests[_id].company==msg.sender,"You are not the company !");
        users[_add].reputation--;
    }

}  