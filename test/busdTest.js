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







let BUSD, ProofOfBurn, signers, owner, issuer, recipient, busd, pob

describe('BUSD', () => {
  beforeEach(async () => {
    signers = await ethers.getSigners()

    ;([owner, issuer, recipient] = signers)


    const BUSDFactory = await ethers.getContractFactory('BUSD', owner)
    const ProofOfBurnFactory = await ethers.getContractFactory('ProofOfBurn', owner)


    BUSD = await BUSDFactory.deploy()
    await BUSD.deployed()
    ProofOfBurn = await ProofOfBurnFactory.attach(
      await BUSD.proofOfBurn()
    )


    busd = (s) => BUSD.connect(s)
    pob = (s) => ProofOfBurn.connect(s)
  })



  describe('init', () => {
    it('should work', async () => {

      expect(await busd(owner).proofOfBurn()).to.equal(ProofOfBurn.address)
      expect(await pob(owner).busd()).to.equal(BUSD.address)

      expect(await busd(owner).issuer()).to.equal(owner.address)
      expect(await busd(owner).totalSupply()).to.equal(0)
      expect(await busd(owner).billsBurned()).to.equal(0)

      expect(await pob(owner).totalSupply()).to.equal(0)
      expect(await pob(owner).exists(0)).to.equal(false)


      await busd(owner).assignIssuer(issuer.address)

      expect(await busd(owner).issuer()).to.equal(issuer.address)

    })
  })

  describe('minting', () => {
    it('should work', async () => {
      await expectRevert(
        busd(issuer).mint(issuer.address, 100, 'abc123', true, 0),
        'Only the Issuer can execute this action'
      )

      await expectRevert(
        busd(issuer).assignIssuer(issuer.address),
        'Ownable: caller is not the owner'
      )

      await busd(owner).assignIssuer(issuer.address)

      expect(await busd(owner).issuer()).to.equal(issuer.address)
      await busd(issuer).mint(issuer.address, 100, 'abc123', true, 0)

      const ts0 = Number(await time.latest())


      expect(await busd(owner).billsBurned()).to.equal(1)
      expect(ethVal(await busd(owner).balanceOf(issuer.address))).to.equal(100)
      expect(ethVal(await busd(owner).totalSupply())).to.equal(100)

      expect(await pob(owner).totalSupply()).to.equal(1)
      expect(await pob(owner).exists(0)).to.equal(true)
      expect(await pob(owner).ownerOf(0)).to.equal(issuer.address)


      await busd(issuer).mint(recipient.address, 50, 'xyz123', false, 2000)
      const ts1 = Number(await time.latest())

      expect(await busd(owner).billsBurned()).to.equal(2)
      expect(ethVal(await busd(owner).totalSupply())).to.equal(150)
      expect(ethVal(await busd(owner).balanceOf(recipient.address))).to.equal(40)
      expect(ethVal(await busd(owner).balanceOf(owner.address))).to.equal(10)

      expect(await pob(owner).totalSupply()).to.equal(2)
      expect(await pob(owner).exists(1)).to.equal(true)
      expect(await pob(owner).ownerOf(1)).to.equal(owner.address)

      expect(await busd(owner).serials(0)).to.equal('abc123')
      expect(await busd(owner).serials(1)).to.equal('xyz123')

      expect(await busd(owner).denominations(0)).to.equal(100)
      expect(await busd(owner).denominations(1)).to.equal(50)

      expect(Number(await busd(owner).timestamps(0))).to.equal(ts0)
      expect(Number(await busd(owner).timestamps(1))).to.equal(ts1)


    })
  })


  describe('burning', () => {
    it('should work', async () => {
      await busd(owner).assignIssuer(issuer.address)

      expect(await busd(recipient).busdBurnedBy(recipient.address)).to.equal(0)

      await expectRevert(
        busd(recipient).burn(1),
        'ERC20: burn amount exceeds balance'
      )


      await busd(issuer).mint(recipient.address, 100, 'abc123', true, 0)
      expect(await pob(recipient).totalSupply()).to.equal(1)

      await busd(recipient).burn(toETH(1))


      expect(await busd(recipient).busdBurnedBy(recipient.address)).to.equal(toETH(1))
      expect(await busd(recipient).totalSupply()).to.equal(toETH(99))
      expect(await busd(recipient).balanceOf(recipient.address)).to.equal(toETH(99))



      await expectRevert(
        pob(recipient).burn(0),
        'ERC20: burn amount exceeds balance'
      )

      await expectRevert(
        pob(owner).burn(0),
        'ERC721: caller is not token owner or approved'
      )

      await pob(recipient).approve(owner.address, 0)

      await expectRevert(
        pob(recipient).burn(0),
        'ERC20: burn amount exceeds balance'
      )

      await busd(issuer).mint(recipient.address, 1, 'def456', true, 0)
      await pob(owner).burn(0)


      expect(await busd(recipient).totalSupply()).to.equal(0)
      expect(await busd(recipient).balanceOf(recipient.address)).to.equal(0)
      expect(await busd(recipient).busdBurnedBy(recipient.address)).to.equal(toETH(101))


      await busd(issuer).mint(recipient.address, 100, 'xyz123', true, 0)
      await busd(issuer).mint(owner.address, 50, 'qwe777', true, 0)
      expect(await pob(owner).totalSupply()).to.equal(3)
      expect(await busd(owner).totalSupply()).to.equal(toETH(150))

      await pob(recipient).approve(owner.address, 2)
      await pob(owner).burn(2)

      expect(await pob(owner).totalSupply()).to.equal(2)



      expect(await busd(recipient).totalSupply()).to.equal(toETH(50))
      expect(await busd(recipient).balanceOf(owner.address)).to.equal(toETH(50))
      expect(await busd(recipient).balanceOf(recipient.address)).to.equal(0)

      expect(await busd(recipient).busdBurnedBy(recipient.address)).to.equal(toETH(201))

      expect(await pob(owner).totalSupply()).to.equal(2)
      expect(await busd(owner).totalSupply()).to.equal(toETH(50))


      await expectRevert(
        busd(recipient).burnFrom(owner.address, toETH(10)),
        'ERC20: insufficient allowance'
      )

      await busd(owner).approve(recipient.address, toETH(10))
      await busd(recipient).burnFrom(owner.address, toETH(10))
      expect(await busd(owner).busdBurnedBy(owner.address)).to.equal(toETH(10))
      expect(await busd(recipient).balanceOf(owner.address)).to.equal(toETH(40))

      expect(await pob(owner).proofsBurned()).to.equal(2)
    })
  })


  describe('metadata', () => {
    it('should work', async () => {
      await busd(owner).assignIssuer(issuer.address)

      await busd(issuer).mint(recipient.address, 100, 'abc123', true, 0)
      await busd(issuer).mint(recipient.address, 100, 'xyz123', true, 0)
      await busd(issuer).mint(recipient.address, 100, 'def456', true, 0)
      await busd(issuer).mint(recipient.address, 100, 'gih789', true, 0)

      expect(await busd(issuer).billsBurned()).to.equal(4)
      expect(await pob(issuer).totalSupply()).to.equal(4)

      await expectRevert(
        busd(recipient).addProof(0, 'proof'),
        'Only the Issuer can execute this action'
      )

      await expectRevert(
        busd(recipient).addProofBatch([1, 2], 'proof://123', '.mov'),
        'Only the Issuer can execute this action'
      )

      await expectRevert(
        busd(recipient).addMemo(1, 'something got fucked up'),
        'Only the Issuer can execute this action'
      )


      await busd(issuer).addProof(0, 'proof')
      await busd(issuer).addProofBatch([1, 2], 'proof://123', '.mov')
      await busd(issuer).addProofBatch([3], 'proof://456', '')

      expect(await busd(owner).proofs(0)).to.equal('proof')
      expect(await busd(owner).proofs(1)).to.equal('proof://123/0.mov')
      expect(await busd(owner).proofs(2)).to.equal('proof://123/1.mov')
      expect(await busd(owner).proofs(3)).to.equal('proof://456/0')

      await busd(issuer).addProofBatch([0, 1, 2, 3], 'proof://abcdefg', '.mp4')

      expect(await busd(owner).proofs(0)).to.equal('proof://abcdefg/0.mp4')
      expect(await busd(owner).proofs(1)).to.equal('proof://abcdefg/1.mp4')
      expect(await busd(owner).proofs(2)).to.equal('proof://abcdefg/2.mp4')
      expect(await busd(owner).proofs(3)).to.equal('proof://abcdefg/3.mp4')

      await busd(issuer).addMemo(0, 'updating proof')

      expect(await busd(owner).memos(0)).to.equal('updating proof')
      expect(await busd(owner).memos(1)).to.equal('')
      expect(await busd(owner).memos(2)).to.equal('')
      expect(await busd(owner).memos(3)).to.equal('')


      console.log(getJsonURI(await pob(owner).tokenURI(0)))
      console.log(getJsonURI(await pob(owner).tokenURI(1)))
    })
  })

})


