
import { describe, expect, it } from "vitest";
import {
  Cl,
  ClarityType,
  type ClarityValue,
  type ResponseOkCV,
  type UIntCV,
} from "@stacks/transactions";

const contract = "PubDex";
const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;
const providerA = accounts.get("wallet_1")!;
const providerB = accounts.get("wallet_2")!;
const verifier1 = accounts.get("wallet_3")!;
const verifier2 = accounts.get("wallet_4")!;
const verifier3 = accounts.get("wallet_5")!;
const providerC = accounts.get("wallet_6")!;
const providerD = accounts.get("wallet_7")!;
const reporter = accounts.get("wallet_6")!;

const hashA = Cl.bufferFromHex("01".repeat(32));
const hashB = Cl.bufferFromHex("02".repeat(32));
const hashC = Cl.bufferFromHex("03".repeat(32));
const hashD = Cl.bufferFromHex("04".repeat(32));

const metadataA = Cl.bufferFromAscii("metadata-a");
const metadataB = Cl.bufferFromAscii("metadata-b");
const metadataC = Cl.bufferFromAscii("metadata-c");

const categoryA = Cl.bufferFromAscii("alpha");
const categoryB = Cl.bufferFromAscii("beta");
const categoryC = Cl.bufferFromAscii("gamma");
const evidenceType = Cl.bufferFromAscii("false-verification");
const statusValidated = Cl.bufferFromHex("0d0000000976616c696461746564");

function unwrapOk(result: ClarityValue): ResponseOkCV {
  expect(result).toHaveClarityType(ClarityType.ResponseOk);
  return result as ResponseOkCV;
}

function unwrapOkUint(result: ClarityValue): bigint {
  const ok = unwrapOk(result);
  expect(ok.value).toHaveClarityType(ClarityType.UInt);
  return BigInt((ok.value as UIntCV).value);
}

describe("PubDex core flows", () => {
  it("approves, stakes, and submits an index", () => {
    const approve = simnet.callPublicFn(
      contract,
      "approve-provider",
      [Cl.standardPrincipal(providerA)],
      deployer,
    );
    expect(approve.result).toBeOk(Cl.bool(true));

    const stake = simnet.callPublicFn(contract, "stake", [Cl.uint(1_000_000)], providerA);
    expect(stake.result).toBeOk(Cl.bool(true));

    const submit = simnet.callPublicFn(
      contract,
      "submit-index",
      [hashA, metadataA, categoryA],
      providerA,
    );
    expect(submit.result).toBeOk(expect.anything());

    const indexId = unwrapOkUint(submit.result);
    const index = simnet.callReadOnlyFn(contract, "get-index", [Cl.uint(indexId)], providerA);
    const indexOk = unwrapOk(index.result);
    expect(indexOk.value).toBeTuple({
      "data-hash": hashA,
      metadata: metadataA,
      owner: Cl.standardPrincipal(providerA),
      verified: Cl.bool(false),
      "verification-count": Cl.uint(0),
      "created-at": expect.anything(),
      category: categoryA,
    });

    const rewards = simnet.callReadOnlyFn(
      contract,
      "get-reward-balance",
      [Cl.standardPrincipal(providerA)],
      providerA,
    );
    expect(rewards.result).toBeOk(Cl.uint(10_000));
  });

  it("verifies an index through a 3-verifier quorum", () => {
    const approve = simnet.callPublicFn(
      contract,
      "approve-provider",
      [Cl.standardPrincipal(providerB)],
      deployer,
    );
    expect(approve.result).toBeOk(Cl.bool(true));

    const stake = simnet.callPublicFn(contract, "stake", [Cl.uint(1_000_000)], providerB);
    expect(stake.result).toBeOk(Cl.bool(true));

    const stakeVerifier1 = simnet.callPublicFn(
      contract,
      "stake-as-verifier",
      [Cl.uint(5_000)],
      verifier1,
    );
    expect(stakeVerifier1.result).toBeOk(Cl.bool(true));

    const stakeVerifier2 = simnet.callPublicFn(
      contract,
      "stake-as-verifier",
      [Cl.uint(5_000)],
      verifier2,
    );
    expect(stakeVerifier2.result).toBeOk(Cl.bool(true));

    const stakeVerifier3 = simnet.callPublicFn(
      contract,
      "stake-as-verifier",
      [Cl.uint(5_000)],
      verifier3,
    );
    expect(stakeVerifier3.result).toBeOk(Cl.bool(true));

    const submit = simnet.callPublicFn(
      contract,
      "submit-index",
      [hashB, metadataB, categoryB],
      providerB,
    );
    const indexId = unwrapOkUint(submit.result);

    const verifierList = Cl.list([
      Cl.standardPrincipal(verifier1),
      Cl.standardPrincipal(verifier2),
      Cl.standardPrincipal(verifier3),
    ]);
    const request = simnet.callPublicFn(
      contract,
      "request-verification",
      [Cl.uint(indexId), verifierList],
      providerB,
    );
    const verificationId = unwrapOkUint(request.result);

    const vote1 = simnet.callPublicFn(
      contract,
      "verify-index",
      [Cl.uint(verificationId), Cl.bool(true)],
      verifier1,
    );
    expect(vote1.result).toBeOk(Cl.bool(true));

    const vote2 = simnet.callPublicFn(
      contract,
      "verify-index",
      [Cl.uint(verificationId), Cl.bool(true)],
      verifier2,
    );
    expect(vote2.result).toBeOk(Cl.bool(true));

    const vote3 = simnet.callPublicFn(
      contract,
      "verify-index",
      [Cl.uint(verificationId), Cl.bool(true)],
      verifier3,
    );
    expect(vote3.result).toBeOk(Cl.bool(true));

    const index = simnet.callReadOnlyFn(contract, "get-index", [Cl.uint(indexId)], providerB);
    const indexOk = unwrapOk(index.result);
    expect(indexOk.value).toBeTuple({
      "data-hash": hashB,
      metadata: metadataB,
      owner: Cl.standardPrincipal(providerB),
      verified: Cl.bool(true),
      "verification-count": Cl.uint(1),
      "created-at": expect.anything(),
      category: categoryB,
    });

    const performance = simnet.callReadOnlyFn(
      contract,
      "get-verifier-performance",
      [Cl.standardPrincipal(verifier3)],
      verifier3,
    );
    const performanceOk = unwrapOk(performance.result);
    expect(performanceOk.value).toBeTuple({
      "correct-verifications": Cl.uint(1),
      "total-verifications": Cl.uint(1),
      "stake-slashed": Cl.uint(0),
      "reputation-score": Cl.uint(510),
    });
  });

  it("allows providers to withdraw rewards", () => {
    const approve = simnet.callPublicFn(
      contract,
      "approve-provider",
      [Cl.standardPrincipal(providerC)],
      deployer,
    );
    expect(approve.result).toBeOk(Cl.bool(true));

    const stake = simnet.callPublicFn(contract, "stake", [Cl.uint(1_000_000)], providerC);
    expect(stake.result).toBeOk(Cl.bool(true));

    const submit = simnet.callPublicFn(
      contract,
      "submit-index",
      [hashC, metadataC, categoryC],
      providerC,
    );
    expect(submit.result).toBeOk(expect.anything());

    const rewardsBefore = simnet.callReadOnlyFn(
      contract,
      "get-reward-balance",
      [Cl.standardPrincipal(providerC)],
      providerC,
    );
    expect(rewardsBefore.result).toBeOk(Cl.uint(10_000));

    const withdraw = simnet.callPublicFn(contract, "withdraw-rewards", [], providerC);
    expect(withdraw.result).toBeOk(Cl.uint(10_000));

    const rewardsAfter = simnet.callReadOnlyFn(
      contract,
      "get-reward-balance",
      [Cl.standardPrincipal(providerC)],
      providerC,
    );
    expect(rewardsAfter.result).toBeOk(Cl.uint(0));
  });

  it("processes slashing evidence with validator quorum", () => {
    const approve = simnet.callPublicFn(
      contract,
      "approve-provider",
      [Cl.standardPrincipal(providerD)],
      deployer,
    );
    expect(approve.result).toBeOk(Cl.bool(true));

    const stake = simnet.callPublicFn(contract, "stake", [Cl.uint(1_000_000)], providerD);
    expect(stake.result).toBeOk(Cl.bool(true));

    const evidenceHash = hashD;
    const submitEvidence = simnet.callPublicFn(
      contract,
      "submit-slashing-evidence",
      [Cl.standardPrincipal(providerD), evidenceType, evidenceHash],
      reporter,
    );
    const evidenceId = unwrapOkUint(submitEvidence.result);

    const addValidator1 = simnet.callPublicFn(
      contract,
      "add-evidence-validator",
      [Cl.standardPrincipal(verifier1)],
      deployer,
    );
    expect(addValidator1.result).toBeOk(Cl.bool(true));

    const addValidator2 = simnet.callPublicFn(
      contract,
      "add-evidence-validator",
      [Cl.standardPrincipal(verifier2)],
      deployer,
    );
    expect(addValidator2.result).toBeOk(Cl.bool(true));

    const addValidator3 = simnet.callPublicFn(
      contract,
      "add-evidence-validator",
      [Cl.standardPrincipal(verifier3)],
      deployer,
    );
    expect(addValidator3.result).toBeOk(Cl.bool(true));

    const vote1 = simnet.callPublicFn(
      contract,
      "validate-slashing-evidence",
      [Cl.uint(evidenceId), Cl.bool(true)],
      verifier1,
    );
    expect(vote1.result).toBeOk(Cl.bool(true));

    const vote2 = simnet.callPublicFn(
      contract,
      "validate-slashing-evidence",
      [Cl.uint(evidenceId), Cl.bool(true)],
      verifier2,
    );
    expect(vote2.result).toBeOk(Cl.bool(true));

    const vote3 = simnet.callPublicFn(
      contract,
      "validate-slashing-evidence",
      [Cl.uint(evidenceId), Cl.bool(true)],
      verifier3,
    );
    expect(vote3.result).toBeOk(Cl.bool(true));

    const evidence = simnet.callReadOnlyFn(
      contract,
      "get-slashing-evidence",
      [Cl.uint(evidenceId)],
      verifier1,
    );
    const evidenceOk = unwrapOk(evidence.result);
    expect(evidenceOk.value).toBeTuple({
      accused: Cl.standardPrincipal(providerD),
      "evidence-type": evidenceType,
      "evidence-hash": evidenceHash,
      reporter: Cl.standardPrincipal(reporter),
      "stake-at-risk": Cl.uint(1_000_000),
      "challenge-deadline": expect.anything(),
      status: statusValidated,
      "validator-votes": Cl.uint(2),
      "required-votes": Cl.uint(3),
    });

    const stakeAfter = simnet.callReadOnlyFn(
      contract,
      "get-stake",
      [Cl.standardPrincipal(providerD)],
      providerD,
    );
    expect(stakeAfter.result).toBeOk(Cl.uint(750_000));
  });
});
