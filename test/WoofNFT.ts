import { ethers } from "hardhat"
import { expect } from "chai"
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers"
import { MerkleTree } from "merkletreejs"
import { BigNumber, Contract } from "ethers"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"

const contractName = "WoofNFT"

type AllowListType = [string, number][]

async function deployContractFixture() {
  const [owner, account1, account2] = await ethers.getSigners()
  const contract = await ethers.deployContract(contractName, [
    "https://example.com",
  ])
  // update contract parameter
  await contract.setMaxMintablePerAddress(1_000)
  const maxMintablePerAddress = await contract.maxMintablePerAddress()

  return {
    contract,
    maxMintablePerAddress,
    owner,
    account1,
    account2,
  }
}

async function preparePreSaleFixture(
  contract: Contract,
  owner: SignerWithAddress,
  sender: SignerWithAddress,
  demand: number,
  allowList: AllowListType
) {
  const price: BigNumber = await contract.preSalePrice()
  const value = price.mul(demand)

  const { keccak256 } = ethers.utils
  const leaf = allowList.map((data) =>
    ethers.utils.solidityKeccak256(["address", "uint256"], [data[0], data[1]])
  )
  const merkleTree = new MerkleTree(leaf, keccak256, { sortPairs: true })
  const allowlistRootHash = merkleTree.getHexRoot()
  await contract.connect(owner).setAllowlist(allowlistRootHash)

  const proof = merkleTree.getHexProof(
    leaf[allowList.findIndex((data) => data[0] === sender.address)]
  )

  return { price, value, merkleTree, proof }
}

async function calculatePublicSaleValueFixture(
  contract: Contract,
  owner: SignerWithAddress,
  demand: number
) {
  await contract.connect(owner).setPublicSalePaused(false)
  await contract.connect(owner).setPreSalePaused(true)

  const price: BigNumber = await contract.publicSalePrice()
  const value = await contract.calculateCost(demand)

  return { price, value }
}

describe("CastyWoof", function () {
  describe("deploy", function () {
    it("should initialize properly", async function () {
      const { contract } = await loadFixture(deployContractFixture)
      console.log("contract: ", contract.address)

      expect(await contract.symbol()).to.equal("CastyWoof")
      expect(await contract.preSalePrice()).to.equal(
        ethers.utils.parseEther("500")
      )
      expect(await contract.preSalePaused()).to.equal(false)
      expect(await contract.publicSalePaused()).to.equal(true)
      expect(await contract.maxSupply()).to.equal(1000)
    })
  })

  // TODO: implement tests
})
