// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {

  // <owner>
  address public owner ;
  
  // <skuCount>
  uint public skuCount;

  // <items mapping> skuCount => Item
  mapping (uint => Item) public items;

  // <enum State: ForSale, Sold, Shipped, Received>
   enum State {
        ForSale,
        Sold,
        Shipped,
        Received
    }

  // <struct Item: name, sku, price, state, seller, and buyer>
  struct Item {
        string name;
        uint sku;
        uint price;
        address payable seller;
        address payable buyer;
        State state;
       
    }
  
  /* 
   * Events
   */

  // <LogForSale event: sku arg>
  event LogForSale(uint sku);
  event LogForItems(Item i);
  // <LogSold event: sku arg>
  event LogSold(uint sku);

  // <LogShipped event: sku arg>
  event LogShipped(uint sku);
  // <LogReceived event: sku arg>
  event LogReceived(uint sku);

  /* 
   * Modifiers
   */

  // Create a modifer, `isOwner` that checks if the msg.sender is the owner of the contract

  // <modifier: isOwner

    modifier isOwner (address _address) { 
    require(msg.sender == owner, "Not owner");
    _;
  }

  modifier verifyCaller (address _address) { 
     require (msg.sender == _address); 
    _;
  }

  modifier paidEnough(uint _sku) { 
    uint _price = items[_sku].price;
     require(msg.value >= _price); 
    _;
  }

    modifier isSeller(uint _sku) { 
    address _seller = items[_sku].seller;
     require(msg.sender == _seller); 
    _;
  }

    modifier isBuyer(uint _sku) { 
    address _buyer = items[_sku].buyer;
     require(msg.sender == _buyer); 
    _;
  }

  modifier checkValue(uint _sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    _;
     uint _price = items[_sku].price;
     uint amountToRefund = msg.value - _price;
     payable(items[_sku].buyer).transfer(amountToRefund);
  }

  // For each of the following modifiers, use what you learned about modifiers
  // to give them functionality. For example, the forSale modifier should
  // require that the item with the given sku has the state ForSale. Note that
  // the uninitialized Item.State is 0, which is also the index of the ForSale
  // value, so checking that Item.State == ForSale is not sufficient to check
  // that an Item is for sale. Hint: What item properties will be non-zero when
  // an Item has been added?

   modifier forSale(uint  _sku){
    // emit LogForItems(items[_sku]);
     State _state = items[_sku].state;
     address _buyer = items[_sku].buyer;
    //require(_state == State.ForSale );
    _;
   }
   modifier sold(uint _sku) {
     State _state = items[_sku].state;
     require(_state == State.Sold);
    _;
   }
   modifier shipped(uint _sku) {
       State _state = items[_sku].state;
     require(_state == State.Shipped);
    _;
   }
   modifier received(uint _sku) {
       State _state = items[_sku].state;
     require(_state == State.Received);
    _;
   }

  constructor() {
    // 1. Set the owner to the transaction sender
    owner =  msg.sender;
    // 2. Initialize the sku count to 0. Question, is this necessary?
    skuCount=0;
  }

  function addItem(string memory _name, uint _price) public returns (bool) {
    // 1. Create a new item and put in array
    // 2. Increment the skuCount by one
    // 3. Emit the appropriate event
    // 4. return true

    // hint:
      items[skuCount] = Item({
          name: _name, 
          sku: skuCount, 
          price: _price, 
          state: State.ForSale, 
          seller: payable(msg.sender),
          buyer: payable(address(0))
      });
    //
    skuCount = skuCount + 1;
     emit LogForSale(skuCount);
     return true;
  }

  // Implement this buyItem function. 
  // 1. it should be payable in order to receive refunds
  
  
  // 5. this function should use 3 modifiers to check (IMplemented in method sign)
  //    - if the buyer paid enough, 
  //    - check the value after the function is called to make 
  //      sure the buyer is refunded any excess ether sent. 
//forSale(sku) paidEnough(sku) checkValue(sku) 
  function buyItem(uint sku) external payable forSale(sku) paidEnough(sku) checkValue(sku)  {
    

    Item memory item = items[sku];
    
    if(item.price <= msg.value) {
      // 2. this should transfer money to the seller, 
        payable(item.seller).transfer(item.price);
      // 3. set the buyer as the person who called this transaction, 
        item.buyer = payable(msg.sender);
        // 4. set the state to Sold. 
        item.state = State.Sold;
        items[sku]=item;
      // 6. call the event associated with this function!
        emit LogSold(sku);
      }
      else {

        require(item.price >= msg.value, "Amount must be greater or equal to item price.");
        revert();
      }
  }

  // 1. Add modifiers to check:
  //    - the item is sold already 
  //    - the person calling this function is the seller. 
  

  function shipItem(uint sku) public sold(sku) isSeller(sku){
      // 2. Change the state of the item to shipped. 
      items[sku].state = State.Shipped;
        // 3. call the event associated with this function!
      emit LogShipped(skuCount);
  }

  // 1. Add modifiers to check 
  //    - the item is shipped already 
  //    - the person calling this function is the buyer. 


  function receiveItem(uint sku) public  shipped(sku) isBuyer(sku) {

      // 2. Change the state of the item to received. 

      items[sku].state = State.Received;
      // 3. Call the event associated with this function!
      emit LogReceived(skuCount);

  }

  // Uncomment the following code block. it is needed to run tests

   function fetchItem(uint _sku) public  view
    returns (string memory name, uint sku, uint price, uint state, address seller, address buyer) 
  { 
    name = items[_sku].name; 
    sku = items[_sku].sku; 
    price = items[_sku].price; 
    state = uint(items[_sku].state); 
    seller = items[_sku].seller; 
    buyer = items[_sku].buyer; 
    return (name, sku, price, state, seller, buyer); 
  } 
}
