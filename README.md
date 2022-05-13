**Project Name:** Capture The Flag

**Title:** Invincibility Via ERC-721 Re-entrancy

**Description:**

It is possible to get a balance of more than 3 mons per user by re-entering the `Game.sol` contract through the `onERC721Received` function.

When a swap is initiated, after the first `_safeTransfer` (line 154), we can re-enter `Game.sol` and recursively swap until the counterparty is drained, at which point they can invoke `join()` again and get another 3 mons.

Repeat this a second time and we can have an account with 9 total mons.

When we have 9 mons, we can `fight()` the invincible deployer and always win as the condition `balanceOf(attacker) > balanceOf(opponent)` (line 75) always holds.
