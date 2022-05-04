// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Game} from "./Game.sol";
import {Bob} from "./Bob.sol";
import {IERC721Receiver} from "./IERC721Receiver.sol";

contract Alice is IERC721Receiver {
    address public immutable s_owner;
    Game public immutable s_game;
    uint256 s_currMonId;
    Bob public s_bob;

    uint256 s_deckCounter;
    uint256[] s_deck;

    constructor(address owner, Game game) {
        s_owner = owner;
        s_game = game;
    }

    function setBob(Bob bob) external {
        require(msg.sender == s_owner, "only owner");
        s_bob = bob;
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        // We're in the middle of a swap. Keep swapping until Bob is empty!
        if (s_game.balanceOf(address(s_bob)) > 0) {
            s_bob.swap(s_deck[s_deckCounter++]);
        } else {
            // Bob is empty!
            s_bob.joinGame(true);
        }

        return IERC721Receiver.onERC721Received.selector;
    }

    function begin() external {
        require(msg.sender == s_owner, "only owner");

        // Join game, put all mons up for sale
        uint256[3] memory deck = s_game.join();
        for (uint256 i; i < 3; i++) {
            s_game.putUpForSale(deck[i]);
            s_deck.push(deck[i]);
        }
        // Get Bob to buy the first one
        s_bob.joinGame(false);
        s_deckCounter = 1;
        s_bob.swap(deck[0]);
    }
}
