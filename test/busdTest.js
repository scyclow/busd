const { expect } = require('chai')
const { ethers, waffle } = require('hardhat')
const { expectRevert, time, snapshot, balance } = require('@openzeppelin/test-helpers')

const toETH = amt => ethers.utils.parseEther(String(amt))
const txValue = amt => ({ value: toETH(amt) })
const ethVal = n => Number(ethers.utils.formatEther(n))
const num = n => Number(n)

const getBalance = async a => ethVal(await ethers.provider.getBalance(a.address))

function times(t, fn) {
  const out = []
  for (let i = 0; i < t; i++) out.push(fn(i))
  return out
}

const utf8Clean = raw => raw.replace(/data.*utf8,/, '')
const b64Clean = raw => raw.replace(/data.*,/, '')
const b64Decode = raw => Buffer.from(b64Clean(raw), 'base64').toString('utf8')
const getJsonURI = rawURI => JSON.parse(utf8Clean(rawURI))
const getSVG = rawURI => b64Decode(JSON.parse(utf8Clean(rawURI)).image)










const ONE_DAY = 60 * 60 * 24
const TEN_MINUTES = 60 * 10
const ZERO_ADDR = '0x0000000000000000000000000000000000000000'
const safeTransferFrom = 'safeTransferFrom(address,address,uint256)'

const contractBalance = contract => contract.provider.getBalance(contract.address)







let BUSD, ProofOfBurn, BurnCeremony, BurnAgreement, signers, owner, burnAgent, recipient, busd, pob, ceremony, agreement

describe('BUSD', () => {
  beforeEach(async () => {
    signers = await ethers.getSigners()

    ;([owner, burnAgent, recipient] = signers)

    const BUSDFactory = await ethers.getContractFactory('BUSD', owner)
    const BurnCeremonyFactory = await ethers.getContractFactory('BurnCeremony', owner)
    const ProofOfBurnFactory = await ethers.getContractFactory('ProofOfBurn', owner)
    const BurnAgreementFactory = await ethers.getContractFactory('BurnAgreement', owner)


    BUSD = await BUSDFactory.deploy()
    await BUSD.deployed()

    ProofOfBurn = await ProofOfBurnFactory.attach(
      await BUSD.proofOfBurn()
    )


    BurnCeremony = await BurnCeremonyFactory.attach(
      await BUSD.ceremony()
    )

    BurnAgreement = await BurnAgreementFactory.deploy(BurnCeremony.address)


    busd = (s) => BUSD.connect(s)
    pob = (s) => ProofOfBurn.connect(s)
    ceremony = (s) => BurnCeremony.connect(s)
    agreement = (s) => BurnAgreement.connect(s)
  })



  describe('init', () => {
    it('should work', async () => {

      expect(await busd(owner).proofOfBurn()).to.equal(ProofOfBurn.address)
      expect(await busd(owner).ceremony()).to.equal(BurnCeremony.address)


      expect(await busd(owner).totalSupply()).to.equal(0)
      expect(await pob(owner).billsBurned()).to.equal(0)


      expect(await pob(owner).busd()).to.equal(BUSD.address)
      expect(await pob(owner).totalSupply()).to.equal(0)
      expect(await pob(owner).exists(0)).to.equal(false)
      expect(await pob(owner).proofsBurned()).to.equal(0)
      expect(await pob(owner).billsBurned()).to.equal(0)


      expect(await ceremony(owner).burnAgent()).to.equal(owner.address)
      expect(await ceremony(owner).proofOfBurn()).to.equal(ProofOfBurn.address)
      expect(await ceremony(owner).busd()).to.equal(BUSD.address)

      await ceremony(owner).setBurnAgent(burnAgent.address)

      expect(await ceremony(owner).burnAgent()).to.equal(burnAgent.address)

      await expectRevert.unspecified(
        ceremony(owner).init(ZERO_ADDR, ZERO_ADDR)
      )

    })
  })

  describe('minting', () => {
    it('should work', async () => {
      await expectRevert(
        ceremony(burnAgent).mint(burnAgent.address, 100, 'abc123'),
        'Caller is not Burn Agent'
      )

      await expectRevert(
        ceremony(burnAgent).setBurnAgent(burnAgent.address),
        'Ownable: caller is not BUSD owner'
      )

      await ceremony(owner).setBurnAgent(burnAgent.address)

      expect(await ceremony(owner).burnAgent()).to.equal(burnAgent.address)

      await expectRevert(
        busd(burnAgent).mint(burnAgent.address, 100),
        'Can only mint through official Burn Ceremony'
      )


      await ceremony(burnAgent).mint(burnAgent.address, 100, 'abc123')

      const ts0 = Number(await time.latest())


      expect(await pob(owner).billsBurned()).to.equal(1)
      expect(ethVal(await busd(owner).balanceOf(burnAgent.address))).to.equal(100)
      expect(ethVal(await busd(owner).totalSupply())).to.equal(100)

      expect(await pob(owner).totalSupply()).to.equal(1)
      expect(await pob(owner).exists(0)).to.equal(true)
      expect(await pob(owner).ownerOf(0)).to.equal(burnAgent.address)


      await ceremony(burnAgent).mint(recipient.address, 50, 'xyz123')
      const ts1 = Number(await time.latest())

      expect(await pob(owner).billsBurned()).to.equal(2)
      expect(ethVal(await busd(owner).totalSupply())).to.equal(150)
      expect(ethVal(await busd(owner).balanceOf(recipient.address))).to.equal(50)
      expect(ethVal(await busd(owner).balanceOf(owner.address))).to.equal(0)

      expect(await pob(owner).totalSupply()).to.equal(2)
      expect(await pob(owner).exists(1)).to.equal(true)
      expect(await pob(owner).ownerOf(1)).to.equal(recipient.address)

      expect(await pob(owner).serials(0)).to.equal('abc123')
      expect(await pob(owner).serials(1)).to.equal('xyz123')

      expect(await pob(owner).denominations(0)).to.equal(100)
      expect(await pob(owner).denominations(1)).to.equal(50)

      expect(Number(await pob(owner).timestamps(0))).to.equal(ts0)
      expect(Number(await pob(owner).timestamps(1))).to.equal(ts1)



      await expectRevert(
        busd(recipient).modifyCeremony(recipient.address),
        'Ownable: caller is not the owner'
      )

      await busd(owner).modifyCeremony(burnAgent.address)

      await expectRevert(
        ceremony(burnAgent).mint(burnAgent.address, 100, 'abc123'),
        'Can only mint through official Burn Ceremony'
      )


    })
  })


  describe('burning', () => {
    it('should work', async () => {
      await ceremony(owner).setBurnAgent(burnAgent.address)

      expect(await busd(recipient).busdBurnedBy(recipient.address)).to.equal(0)

      await ceremony(burnAgent).mint(recipient.address, 100, 'abc123')
      expect(await pob(recipient).totalSupply()).to.equal(1)
      expect(await pob(recipient).billsBurned()).to.equal(1)
      expect(await pob(recipient).proofsBurned()).to.equal(0)
      expect(await pob(recipient).exists(0)).to.equal(true)

      await expectRevert.unspecified(
        busd(recipient).burnFrom(recipient.address, 1),
      )

      await expectRevert(
        pob(owner).burn(0),
        'ERC721: caller is not token owner or approved'
      )


      await pob(recipient).approve(owner.address, 0)
      await busd(recipient).transfer(burnAgent.address, 1)

      await expectRevert(
        pob(owner).burn(0),
        'ERC20: burn amount exceeds balance'
      )

      await expectRevert(
        pob(recipient).burn(0),
        'ERC20: burn amount exceeds balance'
      )

      await busd(burnAgent).transfer(recipient.address, 1)

      await pob(owner).burn(0)


      expect(await busd(recipient).totalSupply()).to.equal(0)
      expect(await busd(recipient).balanceOf(recipient.address)).to.equal(0)
      expect(await busd(recipient).busdBurnedBy(recipient.address)).to.equal(toETH(100))
      expect(await pob(recipient).burnedBy(0)).to.equal(recipient.address)
      expect(await pob(recipient).totalSupply()).to.equal(0)
      expect(await pob(recipient).billsBurned()).to.equal(1)
      expect(await pob(recipient).proofsBurned()).to.equal(1)
      expect(await pob(recipient).exists(0)).to.equal(false)


      await ceremony(burnAgent).mint(recipient.address, 100, 'xyz123')
      await ceremony(burnAgent).mint(owner.address, 50, 'qwe777')

      expect(await pob(owner).totalSupply()).to.equal(2)
      expect(await pob(owner).billsBurned()).to.equal(3)
      expect(await busd(owner).totalSupply()).to.equal(toETH(150))



      await busd(recipient).transfer(burnAgent.address, 1)

      await expectRevert(
        pob(recipient).burn(1),
        'ERC20: burn amount exceeds balance'
      )

      await busd(burnAgent).transfer(recipient.address, 1)


      await pob(recipient).burn(1)


      expect(await busd(recipient).totalSupply()).to.equal(toETH(50))
      expect(await busd(recipient).balanceOf(recipient.address)).to.equal(0)
      expect(await busd(recipient).busdBurnedBy(recipient.address)).to.equal(toETH(200))
      expect(await pob(recipient).burnedBy(1)).to.equal(recipient.address)
      expect(await pob(recipient).totalSupply()).to.equal(1)
      expect(await pob(recipient).billsBurned()).to.equal(3)
      expect(await pob(recipient).proofsBurned()).to.equal(2)
      expect(await pob(recipient).exists(1)).to.equal(false)
      expect(await pob(recipient).exists(2)).to.equal(true)

    })
  })

  describe('agreement minting', () => {
    it('should work', async () => {
      await expectRevert(
        ceremony(burnAgent).setBurnAgreement(BurnAgreement.address),
        'Ownable: caller is not BUSD owner'
      )


      await ceremony(owner).setBurnAgent(burnAgent.address)

      await ceremony(owner).setBurnAgreement(BurnAgreement.address)

      await expectRevert(
        agreement(recipient).updateURI(recipient.address),
        'Ownable: caller is not the owner'
      )
      await agreement(owner).updateURI(await BurnAgreement.uri())

      expect(await ceremony(burnAgent).burnAgreement()).to.equal(BurnAgreement.address)

      await agreement(owner).setActiveAgreement('1.0.0')
      await agreement(owner).setAgreementMetadata('1.0.0', 'ipfs://12345')

      const ownerStartingBalance = await getBalance(owner)

      await expectRevert(
        agreement(recipient).mint(txValue(0.00999)),
        'Invalid value'
      )

      await agreement(recipient).mint(txValue(0.01))
      // await agreement(recipient).tokenIdToAgreementId(0)

      expect(await agreement(recipient).tokenIdToAgreementId(0)).to.equal('1.0.0')
      expect(await agreement(recipient).activeAgreementId()).to.equal('1.0.0')

      await agreement(owner).setActiveAgreement('1.1.0')
      expect(await agreement(recipient).activeAgreementId()).to.equal('1.1.0')

      await agreement(recipient).mint(txValue(0.01))

      expect(await agreement(recipient).totalSupply()).to.equal(2)
      expect(await agreement(recipient).exists(0)).to.equal(true)
      expect(await agreement(recipient).exists(1)).to.equal(true)

      expect(await agreement(recipient).tokenIdToAgreementId(0)).to.equal('1.0.0')
      expect(await agreement(recipient).tokenIdToAgreementId(1)).to.equal('1.1.0')
      expect(await agreement(recipient).agreementUsed(0)).to.equal(false)
      expect(await agreement(recipient).agreementUsed(1)).to.equal(false)


      await expectRevert(
        agreement(burnAgent).markAgreementUsed(0),
        'Only burn ceremony can use agreement'
      )



      await ceremony(burnAgent).mintWithAgreement(0, 100, 'MB70433235C')
      expect(await agreement(recipient).agreementUsed(1)).to.equal(false)


      expect( await getBalance(owner) - ownerStartingBalance).to.be.closeTo(0, 0.0001)

      await expectRevert(
        agreement(recipient).withdraw(toETH(0.02)),
        'Ownable: caller is not the owner'
      )


      await agreement(owner).withdraw(toETH(0.02))



      const ownerEndingBalance = await getBalance(owner)

      expect(ownerEndingBalance - ownerStartingBalance).to.be.closeTo(0.02, 0.0001)


      console.log(getJsonURI(await agreement(recipient).tokenURI(0)))
      console.log(getJsonURI(await agreement(recipient).tokenURI(1)))
    })
  })


  describe('metadata', () => {
    it('should work', async () => {
      await ceremony(owner).setBurnAgent(burnAgent.address)

      await ceremony(burnAgent).mint(recipient.address, 100, 'MB70433235C')
      await ceremony(burnAgent).mint(recipient.address, 100, 'xyz123')
      await ceremony(burnAgent).mint(recipient.address, 100, 'def456')

      console.log(getJsonURI(await pob(owner).tokenURI(0)))



      expect(await pob(burnAgent).totalSessions()).to.equal(0)
      expect(await pob(owner).tokenIdToSessionId(0)).to.equal(0)

      await pob(burnAgent).markSessionEnd()
      expect(await pob(burnAgent).totalSessions()).to.equal(1)
      expect(await pob(owner).tokenIdToSessionId(0)).to.equal(0)
      expect(await pob(owner).tokenIdToSessionId(1)).to.equal(0)
      expect(await pob(owner).tokenIdToSessionId(2)).to.equal(0)

      await ceremony(burnAgent).mint(recipient.address, 100, 'gih789')

      await pob(burnAgent).markSessionEnd()

      expect(await pob(burnAgent).totalSessions()).to.equal(2)
      expect(await pob(owner).tokenIdToSessionId(3)).to.equal(1)


      expect(await pob(burnAgent).billsBurned()).to.equal(4)
      expect(await pob(burnAgent).totalSupply()).to.equal(4)

      await expectRevert(
        pob(recipient).addProof(0, 'proof'),
        'Caller is not Burn Agent'
      )

      await expectRevert(
        pob(recipient).addProofBatch([1, 2], 'proof://123', '.mov'),
        'Caller is not Burn Agent'
      )

      await expectRevert(
        pob(recipient).addMemo(1, 'something got fucked up'),
        'Caller is not Burn Agent'
      )

      await expectRevert(
        pob(recipient).markSessionEnd(),
        'Caller is not Burn Agent'
      )



      await pob(burnAgent).addProof(0, 'proof')
      await pob(burnAgent).addProofBatch([1, 2], 'proof://123/', '.mov')
      await pob(burnAgent).addProofBatch([3], 'proof://456/', '')

      expect(await pob(owner).proofs(0)).to.equal('proof')
      expect(await pob(owner).proofs(1)).to.equal('proof://123/0.mov')
      expect(await pob(owner).proofs(2)).to.equal('proof://123/1.mov')
      expect(await pob(owner).proofs(3)).to.equal('proof://456/0')

      await pob(burnAgent).addProofBatch([0, 1, 2, 3], 'proof://abcdefg/', '.mp4')

      expect(await pob(owner).proofs(0)).to.equal('proof://abcdefg/0.mp4')
      expect(await pob(owner).proofs(1)).to.equal('proof://abcdefg/1.mp4')
      expect(await pob(owner).proofs(2)).to.equal('proof://abcdefg/2.mp4')
      expect(await pob(owner).proofs(3)).to.equal('proof://abcdefg/3.mp4')

      await pob(burnAgent).addMemo(0, 'updating proof')

      expect(await pob(owner).memos(0)).to.equal('updating proof')
      expect(await pob(owner).memos(1)).to.equal('')
      expect(await pob(owner).memos(2)).to.equal('')
      expect(await pob(owner).memos(3)).to.equal('')


      console.log(getJsonURI(await pob(owner).tokenURI(0)))
      console.log(getJsonURI(await pob(owner).tokenURI(1)))
    })
  })

})


