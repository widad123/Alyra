//import "babel-polyfill"

const Marketplace = artifacts.require("./Marketplace.sol");

require('chai')
  .use(require('chai-as-promised'))
  .should()

contract('Marketplace', async([owner,user1,user2,user3])=>{
    let marketplace

    before(async ()=>{
        marketplace = await Marketplace.deployed();
    
    });

    describe('deployement', async ()=>{
        it('deploys successfuly', async ()=>{
            const address = await marketplace.address;
            assert.notEqual(address, 0x0);
            assert.notEqual(address, '');
            assert.notEqual(address, null);
            assert.notEqual(address, undefined);
        });
    });

    describe('inscription', async () =>{
        let result;
 
        before(async ()=>{
            result = await marketplace.inscription('Lilia',1,{from:user1});
        });
    
        it('creates user', async () =>{
            //success
        const event=result.logs[0].args;
        assert.equal(event._add, user1, "user address is correct");
        assert.equal(event._name, 'Lilia', "name is correct");
        assert.equal(event._reputation, 1, "reputation is correct");
        assert.equal(event._isUser, true, "isUser is correct");
            //failure
        await await marketplace.inscription('',1,{from:user1}).should.be.rejected;
        await await marketplace.inscription('Lilia',0,{from:user1}).should.be.rejected;
         });
        
        it('Users',async () => {
        const users = await marketplace.users(user1);
        assert.equal(users.name, 'Lilia', "name is correct");
        assert.equal(users.reputation, 1, "reputation is correct");
        assert.equal(users.isUser, true, "isUser is correct");
        });

    });

    //Lilia mon amour
    describe('Request', async () =>{
        let result, requestCount,oldBalanceOwner,newBalanceOwner,price;
 
        before(async ()=>{
        //    await marketplace.inscription('Lilia',1,{from:user1});
            await marketplace.inscription('Malika',4,{from:user3});

            oldBalanceOwner= await marketplace.balances(owner);
            oldBalanceOwner = new web3.utils.BN(oldBalanceOwner);

            result = await marketplace.addRequest('first request',3,3,30,{from:user1, value: web3.utils.toWei('3.06','Ether')});
            requestCount = await marketplace.requestCount();
     
        });
     
        it('addRequest', async () =>{
            //success
        const event=result.logs[0].args;
        assert.equal(event._add, user1, "user address is correct");
        assert.equal(event._id.toNumber(), requestCount.toNumber(), "id is correct");
        assert.equal(event._miniReputation, 3, "reputation is correct");
        assert.equal(event._deadline.toNumber(), 259200, "deadline is correct");
        assert.equal(event._startTime.toNumber(),0 , "startTime is correct");
        assert.equal(event._cost.toNumber(), 30, "cost is correct");
        assert.equal(event._description,'first request', "description is correct");
        assert.equal(event._url,'', "url is correct");
        assert.equal(event._state,0, "state is correct");

        //Owner receive founds
        newBalanceOwner = await marketplace.balances(owner);
        newBalanceOwner = new web3.utils.BN(newBalanceOwner);

        price = web3.utils.toWei('3.06','Ether');
        price = new web3.utils.BN(price);

        const expectedBalance = oldBalanceOwner.add(price);
        assert.equal(newBalanceOwner.toString(), expectedBalance.toString());

        //failure
        await await marketplace.addRequest('',3,3,30,{from:user1, value: web3.utils.toWei('3.06','Ether')}).should.be.rejected;
        await await marketplace.addRequest('first request',0,3,30,{from:user1, value: web3.utils.toWei('3.06','Ether')}).should.be.rejected;
        await await marketplace.addRequest('first request',3,0,30,{from:user1, value: web3.utils.toWei('3.06','Ether')}).should.be.rejected;
        await await marketplace.addRequest('first request',3,3,0,{from:user1, value: web3.utils.toWei('3.06','Ether')}).should.be.rejected;
        await await marketplace.addRequest('first request',3,3,30,{from:user1},0).should.be.rejected;
    });
        
         it('requests',async () => {
        const request = await marketplace.requests(1);

        assert.equal(request.company, user1, "user address is correct");
        assert.equal(request.id.toNumber(), requestCount.toNumber(), "id is correct");
        assert.equal(request.miniReputation, 3, "reputation is correct");
        assert.equal(request.deadline.toNumber(), 259200, "deadline is correct");
        assert.equal(request.startTime.toNumber(),0 , "startTime is correct");
        assert.equal(request.remuneration.toNumber(), 30, "cost is correct");
        assert.equal(request.description,'first request', "description is correct");
        assert.equal(request.url,0, "url is correct");
        assert.equal(request.state,0, "state is correct");
    });

        it('can to apply',async () => {
            result = await marketplace.applyTo(1,{from:user3});
  //success
        const event=result.logs[0].args;

        assert.equal(event._id, 1, "id is correct");
        assert.equal(event._add, user3, "address is correct");
        assert.equal(event._reputation, 4, "reputation is correct");
        assert.equal(event._isCandidate, true, "isCandidate is correct"); 

        });

        it('is accepted',async () => {
            result = await marketplace.acceptOffer(1,"0xfc1dc4d7330eb3c426923c02d4198e4ced53f28a",{from:user1});
  //success
        const event=result.logs[0].args;

        assert.equal(event._id, 1, "id is correct");
        assert.equal(event._add, user3, "address is correct");
        assert.equal(event._isAccepted, true, "isAccepted is correct"); 
        });

        it('delivry', async () => {
            result = await marketplace.delivry(1,"www.google.com",{from:user3});

            const event=result.logs[0].args;

            console.log(event);

            assert.equal(event._id, 1, "id is correct");
            assert.equal(event._add, user3, "address is correct");
            assert.equal(event._url, "www.google.com", "url is correct");
            assert.equal(event._reputation,5, "reputation is correct");
        })



    });


});
