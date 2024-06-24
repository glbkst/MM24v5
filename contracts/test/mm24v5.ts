import { expect } from "chai";
import { ethers } from "hardhat";
import { IERC721__factory } from "../typechain-types";

describe("Test", function () {
  it("Test contract", async function () {
    const ContractFactory = await ethers.getContractFactory("MM24v5");

    const [initialOwner, otherAddress, couldbeaSplitAddr ] = await ethers.getSigners();


    let balanceInit = await ethers.provider.getBalance(initialOwner);
    

    const instance = await ContractFactory.deploy(initialOwner, "atestname");
    await instance.waitForDeployment();

    expect(await instance.name()).to.equal("atestname");
    
    await instance.setMaxMints(5);
    await expect( instance.connect(otherAddress).unpause() ).to.be.revertedWithCustomError(instance, "OwnableUnauthorizedAccount");
    await expect( instance.connect(otherAddress).init("t",0) ).to.be.revertedWithCustomError(instance, "OwnableUnauthorizedAccount");

    await expect( instance.connect(otherAddress).safeMint(otherAddress) ).to.be.revertedWithCustomError(instance, "OwnableUnauthorizedAccount");
    await expect( instance.connect(otherAddress).setMaxMints(1000) ).to.be.revertedWithCustomError(instance, "OwnableUnauthorizedAccount");
    await expect( instance.connect(otherAddress).setName("hellosetit") ).to.be.revertedWithCustomError(instance, "OwnableUnauthorizedAccount");
    await expect( instance.connect(otherAddress).updateUri() ).to.be.revertedWithCustomError(instance, "OwnableUnauthorizedAccount");
    await expect( instance.connect(otherAddress).setUri("bla") ).to.be.revertedWithCustomError(instance, "OwnableUnauthorizedAccount");
    await expect( instance.connect(otherAddress).transferOwnership(otherAddress) ).to.be.revertedWithCustomError(instance, "OwnableUnauthorizedAccount");
    await expect( instance.connect(otherAddress).setLicense("none") ).to.be.revertedWithCustomError(instance, "OwnableUnauthorizedAccount");

    await instance.init("t",0);
    const aUriOrg = "123456";

    await instance.setUri(aUriOrg);
    await instance.setMaxMints(5);
    await instance.setMaxMintsL(2);


    await instance.pause();
    await expect( await instance.paused() ).to.be.equal(true);   
    await instance.unpause();

    console.log("new name");
    await instance.setName("iiiii");
    expect(await instance.name()).to.equal("iiiii");
    await instance.setName("");
    expect(await instance.name()).to.equal("atestname");


    expect(await instance.maxMints()).to.equal(5);
    expect(await instance.maxMintsL()).to.equal(2);

    let currentMaxMint = await instance.maxMints();
    console.log("maxmint: %s", currentMaxMint);
    let currentMints = await instance.mintNumber();
    console.log("mints: %s", currentMints);

    currentMaxMint = await instance.maxMints();
    console.log("maxmint: %s", currentMaxMint);
    currentMints = await instance.mintNumber();
    console.log("mints: %s", currentMints);


    const payable = ethers.parseEther("0.0002");
    const payableL = ethers.parseEther("0.00145");
    await instance.setMintPayable(payable/ BigInt(10**9));
    await instance.setMintPayableL(payableL/ BigInt(10**9));


    const interfaceIdERC721 = new Uint8Array([0x80,0xac,0x58,0xcd]);

    expect( await instance.supportsInterface(interfaceIdERC721)).to.be.equal(true);
    interfaceIdERC721[0] = 0x0;
    expect( await instance.supportsInterface(interfaceIdERC721)).to.be.equal(false);


    const aUri = "jfjslfjsdkljfsklfsdfsdfsdfdsf";
    await expect(instance.setUri("")).to.be.revertedWithCustomError(instance, "EmptyNotPossible");
    await instance.setUri(aUri);
    await instance.safeMint(initialOwner);
    currentMaxMint = await instance.maxMints();
    console.log("maxmint: %s", currentMaxMint);
    currentMints = await instance.mintNumber();
    console.log("mints: %s", currentMints);
    expect( await instance.tokenURI(1)).to.be.equal(aUri);    

    await expect(instance.connect(otherAddress).withdraw()).to.be.revertedWithCustomError(instance, "OwnableUnauthorizedAccount");
    await instance.withdraw();
    await expect(instance.connect(otherAddress).pause()).to.be.revertedWithCustomError(instance, "OwnableUnauthorizedAccount");
    await instance.pause();
    await instance.init("a-newuri-2", 7);

    await expect(instance.connect(otherAddress).setWithdrawAddress(otherAddress)).to.be.revertedWithCustomError(instance, "OwnableUnauthorizedAccount");
    await instance.setWithdrawAddress(couldbeaSplitAddr);

    console.log(instance.interface.encodeFunctionData("mint"));

    expect( await instance.mintPayable()).to.be.equal(payable/ BigInt(10**9));
    expect( await instance.mintPayableL()).to.be.equal(payableL/ BigInt(10**9));
    expect( await instance.mintNumberL()).to.be.equal(0);

    await instance.connect(otherAddress).mint({value: payable});
    await instance.connect(otherAddress).mint({value: payable});
    await instance.connect(otherAddress).mint({value: payableL});
    expect( await instance.tokenURI(2)).to.be.equal("a-newuri-2");    
    expect( await instance.tokenURI(4)).to.be.equal("a-newuri-2");    
    await instance.setUriRange("aLUri2024", 4, 4);
    expect( await instance.tokenURI(4)).to.be.equal("aLUri2024");    
    await expect(instance.connect(otherAddress).mint({value: ethers.parseEther("0.1")})).to.be.revertedWithCustomError(instance, "PayableWrong")

    expect( await instance.mintNumberL()).to.be.equal(1);
    await expect(instance.setMaxMintsL(1)).to.be.revertedWithCustomError(instance, "MaxMintsNeedsToBeGreaterThanMintedNumber");


    await instance.setName("newName")
    expect( await instance.name()).to.be.equal("newName")
    expect( await instance.tokenURI(1)).to.be.equal(aUri)
    await instance.updateUri();
    expect( await instance.tokenURI(1)).to.be.equal("a-newuri-2")

    await instance.transferOwnership(otherAddress);
    await instance.connect(otherAddress).setUriRange("rangeuri", 1, 1);
    await instance.connect(otherAddress).transferOwnership(initialOwner);
    await expect( instance.connect(otherAddress).setUriRange("t", 1,1)).to.be.revertedWithCustomError(instance, "OwnableUnauthorizedAccount");
    await instance.setUriRange("rangeuri", 1, 1);
    expect( await instance.tokenURI(1)).to.be.equal("rangeuri");
    await expect(instance.setMaxMints(1)).to.be.revertedWithCustomError(instance, "MaxMintsNeedsToBeGreaterThanMintedNumber");


    await instance.setLicense("All Rights Reserved");

    expect(await instance.getLicense()).to.be.equal("All Rights Reserved");


  });
});
