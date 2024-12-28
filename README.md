# EventHub - Decentralized Ticketing System Smart Contract

Welcome to the **EventHub** decentralized ticketing system built using the **Clarity smart contract** language. This smart contract is designed to handle the sale, refund, and management of event tickets in a secure and decentralized way, leveraging the **Stacks** blockchain for its functionality.

### Overview

The EventHub system enables users to buy, sell, and refund event tickets while ensuring the integrity of the ticketing process. It provides features such as:

- **Ticket Pricing:** The contract owner can set the price for tickets.
- **Refund System:** Users can request refunds for tickets at a configurable rate.
- **Ticket Sale Management:** Users can list tickets for sale and remove them, with checks to prevent unauthorized actions.
- **Ticket Purchase:** Users can purchase tickets from other users and pay the required amount in STX.
- **User Ticket Management:** Each user has a balance of tickets, and they can track the tickets they own and have listed for sale.
- **Reserve Limit:** A maximum limit of tickets can be set, ensuring that ticket sales do not exceed a certain amount.
- **Transaction Failures & Security:** The contract includes error handling for situations like insufficient funds, unauthorized access, or attempted fraudulent transactions.

This system utilizes **Clarity smart contracts** to handle the logic, ensuring transparency, immutability, and decentralization. It’s built to offer efficient ticket management for decentralized events and online ticket marketplaces.

## Features

### 1. **Ticket Pricing Management**
- **set-ticket-price**: Allows the contract owner to set the price of tickets. The price is set in **microstacks** (the smallest unit of STX).

### 2. **Refund System**
- **set-refund-rate**: The contract owner can set a refund rate in percentage, specifying how much of the ticket price can be refunded when a user requests a refund.
- **refund-ticket**: Users can refund their tickets, and they will receive a refund based on the defined refund rate.

### 3. **Ticket Sale Management**
- **add-tickets-for-sale**: Users can add tickets to the marketplace for sale. The system checks that the user has enough tickets and that the ticket price is set.
- **remove-tickets-from-sale**: Users can remove tickets from sale, provided they have enough tickets listed.

### 4. **Purchasing Tickets**
- **buy-ticket**: Users can buy tickets from other sellers, paying the required amount in STX. The contract ensures that the buyer has enough balance and that the seller has enough tickets for sale.

### 5. **Balance Management**
- **user-ticket-balance**: Tracks the balance of tickets owned by each user.
- **user-stx-balance**: Tracks the balance of STX owned by each user.
- **tickets-for-sale**: Tracks the tickets listed for sale by each user.

### 6. **Ticket Reserve Limit**
- The contract has a configurable ticket reserve limit that ensures the system doesn’t oversell tickets beyond a certain amount.

### 7. **Optimizations and Bug Fixes**
- **Optimized functions**: Several functions in the contract have been optimized to reduce gas costs and improve performance.
- **Bug Fixes**: Various fixes are applied to ensure correct refund amounts and streamline ticket purchasing and management.

## Functionality

### **Public Functions**

1. **Set Ticket Price**
   - Function: `set-ticket-price`
   - Description: Allows the contract owner to set the price for tickets.
   - Requirements: Only the contract owner can call this function.

2. **Set Refund Rate**
   - Function: `set-refund-rate`
   - Description: Sets the percentage rate of refunds that a user can claim for their tickets.
   - Requirements: Only the contract owner can call this function.

3. **Set Ticket Reserve Limit**
   - Function: `set-ticket-reserve-limit`
   - Description: Defines the maximum number of tickets that can be sold across all users.
   - Requirements: Only the contract owner can call this function.

4. **Add Tickets for Sale**
   - Function: `add-tickets-for-sale`
   - Description: Allows a user to list tickets for sale. The user must have enough tickets in their balance.
   - Requirements: User must have sufficient tickets to list.

5. **Remove Tickets from Sale**
   - Function: `remove-tickets-from-sale`
   - Description: Allows a user to remove tickets from sale.
   - Requirements: User must have enough tickets listed for sale.

6. **Buy Tickets**
   - Function: `buy-ticket`
   - Description: Allows a user to purchase tickets from another user.
   - Requirements: Buyer must have enough STX, and the seller must have enough tickets listed for sale.

7. **Refund Ticket**
   - Function: `refund-ticket`
   - Description: Allows a user to request a refund for their tickets. The refund will be processed based on the refund rate.
   - Requirements: User must have enough tickets to refund, and there must be sufficient STX in the contract for the refund.

### **Read-Only Functions**

1. **Get Ticket Price**
   - Function: `get-ticket-price`
   - Description: Returns the current price of a ticket.

2. **Get Refund Rate**
   - Function: `get-refund-rate`
   - Description: Returns the current refund rate.

3. **Get User’s Ticket Balance**
   - Function: `get-ticket-balance`
   - Description: Returns the number of tickets owned by a specific user.

4. **Get User’s STX Balance**
   - Function: `get-stx-balance`
   - Description: Returns the STX balance of a user.

5. **Get Tickets for Sale by User**
   - Function: `get-tickets-for-sale`
   - Description: Returns the number of tickets a specific user has listed for sale.

## Error Handling

The contract ensures that users and the contract owner are notified of errors that occur during transactions. Common errors include:

- **err-owner-only**: The function is restricted to the contract owner.
- **err-not-enough-tickets**: User doesn’t have enough tickets to complete the transaction.
- **err-invalid-ticket-price**: The ticket price is invalid (must be greater than zero).
- **err-invalid-ticket-amount**: The ticket amount is invalid (must be greater than zero).
- **err-ticket-transfer-failed**: The ticket transfer failed due to insufficient STX balance.
- **err-reserve-limit-exceeded**: The ticket reserve limit is exceeded.
- **err-same-user**: The buyer and seller cannot be the same user.

## Optimization & Refactor

Several functions in the contract have been optimized to improve gas efficiency and clarity. These include:

- **Optimized Ticket Price Setter**: A streamlined version of the ticket price setter function.
- **Optimized Ticket Purchase**: A more gas-efficient way of handling ticket purchases.
- **Bug Fixes**: Correcting issues such as refund rate calculation bugs.

## Future Enhancements

- **Dynamic Ticket Pricing**: Implement dynamic ticket pricing based on demand.
- **Event Metadata**: Adding support for event metadata, including event name, date, and location.
- **Multi-Currency Support**: Support for additional cryptocurrencies or tokens for ticket purchasing.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

---

**EventHub** is built with the intention of creating a transparent, decentralized, and user-friendly platform for managing event tickets. By using the power of the Stacks blockchain, EventHub ensures that ticket transactions are secure, immutable, and cost-efficient. With built-in refund policies, secure transactions, and efficient ticket management, this system provides a seamless experience for users in the decentralized space.

For more information, feel free to explore the [Clarity Documentation](https://www.claritylang.org/) for a deeper understanding of how smart contracts on the Stacks blockchain work.
