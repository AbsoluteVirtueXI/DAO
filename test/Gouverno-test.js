/* eslint-disable quotes */
/* eslint-disable no-undef */

const { expect } = require('chai');

describe('Gouverno', function () {
  let deployer;
  it('Has name Gouverno', async function () {
    [deployer] = await ethers.getSigners();
    const Gouverno = await ethers.getContractFactory('Gouverno');
    const gouverno = await Gouverno.deploy([deployer.address]);

    await gouverno.deployed();
    expect(await gouverno.name()).to.equal('Gouverno');
  });
});
