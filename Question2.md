## Why does the SafeERC20 program exist and when should it be used?

SafeERC20 offers versions of the safeTransfer and safeTransferFrom functions, which go beyond the traditional transfer methods. These functions not only handle the standard ERC20 tokens, but also accommodate non-standard-compliant tokens like USDT, which does not return a boolean, therefore reverting every single time and leading to a DOS attack on the protocol. The SafeERC20 makes sure to check the size of the returned data and should be always used.
