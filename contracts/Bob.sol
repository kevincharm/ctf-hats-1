// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Game} from "./Game.sol";
import {Alice} from "./Alice.sol";
import {IERC721Receiver} from "./IERC721Receiver.sol";

contract Bob is IERC721Receiver {
    address public immutable s_owner;
    Game public immutable s_game;
    uint256 s_currMonId;
    Alice public s_alice;
    Bob public s_otherBob;

    uint256 s_deckCounter;
    uint256[] s_deck;

    uint256 s_tokenCounter;
    uint256[] s_receivedTokenIds;

    constructor(address owner, Game game) {
        s_owner = owner;
        s_game = game;
    }

    function setAlice(Alice alice) external {
        require(msg.sender == s_owner, "only owner");
        s_alice = alice;
    }

    function setOtherBob(Bob otherBob) external {
        require(msg.sender == s_owner, "only owner");
        s_otherBob = otherBob;
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata
    ) external virtual override returns (bytes4) {
        s_receivedTokenIds.push(tokenId);

        return IERC721Receiver.onERC721Received.selector;
    }

    function swap(uint256 cMonId) external {
        require(msg.sender == address(s_alice), "only alice");

        // Initiate swap -> see you in `onERC721Received`
        s_game.swap(address(s_alice), s_deck[s_deckCounter++], cMonId);
    }

    function swapSelf(uint256 cMonId) external {
        require(msg.sender == address(s_otherBob), "only other bob");
        s_game.swap(msg.sender, s_receivedTokenIds[s_tokenCounter++], cMonId);
    }

    function joinGame(bool recordIds) external {
        require(
            msg.sender == address(s_alice) || msg.sender == address(s_otherBob),
            "only alice or bob"
        );

        // Join game & record deck
        uint256[3] memory deck = s_game.join();
        for (uint256 i; i < 3; i++) {
            s_game.putUpForSale(deck[i]);
            s_deck.push(deck[i]);
            if (recordIds) {
                // We record ids so we can iterate through them again in the last phase
                s_receivedTokenIds.push(deck[i]);
            }
        }
        s_deckCounter = 0;
    }

    function fight() external {
        s_game.fight();
    }
}

contract OtherBob is Bob {
    constructor(address owner, Game game) Bob(owner, game) {}

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        if (from == address(s_otherBob)) {
            // Last phase
            if (s_game.balanceOf(address(s_otherBob)) > 0) {
                // Swap until other Bob is empty
                s_otherBob.swapSelf(s_receivedTokenIds[s_tokenCounter++]);
            } else {
                // Other Bob is empty!
                s_otherBob.joinGame(false);
            }
        } else {
            // First phase
            s_receivedTokenIds.push(tokenId);
        }

        return IERC721Receiver.onERC721Received.selector;
    }

    function beginSwapSelf(Bob otherBob) external {
        require(msg.sender == s_owner, "only owner");
        otherBob.swapSelf(s_receivedTokenIds[s_tokenCounter++]);
    }
}
