const { ethers } = require('@nomiclabs/buidler')
const { use, expect } = require('chai')
const {
  solidity,
  deployContract,
  createFixtureLoader,
} = require('ethereum-waffle')
const { utils, constants } = require('ethers')
const BigNumber = require('bignumber.js')
const DAIHubArtifact = require('../artifacts/TestDAIHub.json')
const MockProxyArtifact = require('../artifacts/MockProxy.json')
const TestTokenArtifact = require('../artifacts/TestToken.json')

use(solidity)

describe('DAIHub', () => {
  const provider = ethers.provider
  let account, mockToken, mockProxy1, mockProxy2, hub
  
  beforeEach(async() => {
    const [wallet] = await ethers.signers()
    account = await wallet.getAddress()
    testToken = await deployContract(wallet, TestTokenArtifact, ['Test', 'TST', 18])
    mockProxy1 = await deployContract(wallet, MockProxyArtifact)
    mockProxy2 = await deployContract(wallet, MockProxyArtifact)
    hub = await deployContract(wallet, DAIHubArtifact, [[mockProxy1.address, mockProxy2.address], testToken.address])

    const approveTx = await testToken.approve(hub.address, constants.MaxUint256)
    await approveTx.wait()
  })

  it('should mint hDAI token when user deposit DAI into hub', async () => {
    const amount = utils.bigNumberify('1000000000000000000')
    await expect(hub.deposit(account, amount)).to.emit(hub, 'Transfer').withArgs(constants.AddressZero, account, amount)
  })

  it('should burn hDAI token when user withdraw DAI from hub', async () => {
    const amount = utils.bigNumberify('1000000000000000000')
    const depositTx = await hub.deposit(account, amount)
    await depositTx.wait()
    await expect(hub.withdraw(account, amount)).to.emit(hub, 'Transfer').withArgs(account, constants.AddressZero, amount)
  })

  it('should redistribute DAI to Proxy in order to investment', async () => {
    const amount = utils.bigNumberify('1000000000000000000')
    const depositTx = await hub.deposit(account, amount)
    await depositTx.wait()

    const totalValueStored = await mockProxy1.totalValueStored()

    const investTx = await hub.invest(mockProxy1.address, amount.div(2))
    await investTx.wait()

    const totalValueStoredNow = await mockProxy1.totalValueStored()

    expect(totalValueStoredNow).to.equal(totalValueStored.add(amount.div(2)))
  })

  it('should redeem DAI from proxy', async () => {
    const amount = utils.bigNumberify('1000000000000000000')
    const depositTx = await hub.deposit(account, amount)
    await depositTx.wait()
    const investTx = await hub.invest(mockProxy1.address, amount.div(2))
    await investTx.wait()

    const totalValueStored = await mockProxy1.totalValueStored()

    const redeemTx = await hub.redeem(mockProxy1.address, amount.div(2))
    await redeemTx.wait()

    const totalValueStoredNow = await mockProxy1.totalValueStored()

    expect(totalValueStoredNow).to.equal(totalValueStored.sub(amount.div(2)))
  })

//   it('should calculate total value in this hub', async () => {
//     const amount = utils.bigNumberify('1000000000000000000')
//     const depositTx = await hub.deposit(account, amount)
//     await depositTx.wait()
//     const invest1Tx = await hub.invest(mockProxy1.address, amount.div(2))
//     await invest1Tx.wait()
//     const invest2Tx = await hub.invest(mockProxy2.address, amount.div(2))
//     await invest2Tx.wait()

//     const totalValueStored = await hub.totalValueStored()

//     expect(totalValueStored).to.equal(amount)
//   })
})

