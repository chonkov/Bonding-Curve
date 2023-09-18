# Rareskills Solidity Bootcamp

## What problems ERC777 and ERC1363 solve?

Both standards offer holders more control over their tokens. With the "old-school" and "basic" ERC-20, when a contract receives a token, there is no way to execute code after a transfer or approval.

Double transactions are not required anymore. Moreover, as code will be executed, recipient (like contract wallets) can deny reception of unwanted tokens by using revert.

## Why was ERC1363 introduced, and what issues are there with ERC777?

ERC1363 makes token payments easier and working without the use of any other listener. It allows to make a callback after a transfer or approval in a single transaction.

ERC777's main security problem is that, just like ether transfers, tokens will be vulnerable to reentrancy attacks, if an external call is made via a hook, before updating the state (Of course, ERC1363 also introduces the same attack vector). Fortunately, this can be fixed (using a mutex for example or making sure that storage variables are udpated prior to making external calls). Another issue is that it is over-engineered and introduces bad abstractions to rely on, making it very complex. The ERC1363 implementation, for example, is much simpler and achieves the same outcome.
