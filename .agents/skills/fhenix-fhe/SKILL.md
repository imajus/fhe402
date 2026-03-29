---
name: fhenix-fhe
description: >
  Write, review, debug, and deploy Fully Homomorphic Encryption (FHE) smart
  contracts using the Fhenix protocol and @fhenixprotocol/cofhe-contracts.
  Use this skill whenever the user mentions FHE, Fhenix, encrypted smart
  contracts, homomorphic encryption, private/confidential on-chain computation,
  encrypted types like ebool or euint8/16/32/64/128/256 or eaddress,
  FHE.allow, FHE.select, cofhe-contracts, or wants to build contracts with
  encrypted state. Also trigger when the user has access-denied errors in FHE
  contracts, wants to understand encrypted conditional logic, needs help with
  FHE decryption workflows, or is debugging issues with encrypted values being
  unusable. Even if they just say "encrypted contract" or "private balance" in
  the context of Solidity/EVM, this skill applies.
---

# Fhenix FHE Smart Contract Development

## Overview

Fhenix brings Fully Homomorphic Encryption (FHE) to the EVM. All encrypted types (`ebool`, `euint8`-`euint256`, `eaddress`) are `uint256` handles pointing to encrypted data on-chain. All operations go through the `FHE.*` library. Access control via `FHE.allow*()` is mandatory -- without it, encrypted values are locked boxes without keys.

```solidity
import "@fhenixprotocol/cofhe-contracts/FHE.sol";
```

Remappings:
```
@fhenixprotocol/cofhe-contracts/=lib/cofhe-contracts/contracts/     // Foundry
@fhenixprotocol/cofhe-contracts/=node_modules/@fhenixprotocol/cofhe-contracts/  // Node
```

## Critical Rules

Follow these rules for every FHE contract. Violating any of them produces broken or unusable code.

1. **Import FHE.sol** -- every contract using encrypted types needs `import "@fhenixprotocol/cofhe-contracts/FHE.sol";`

2. **Always grant access after storing** -- when writing an encrypted value to storage, call both:
   - `FHE.allowThis(value)` -- so the contract can operate on it later
   - `FHE.allowSender(value)` -- so the caller can read/decrypt it

3. **Always grant access on computed values** -- any new value from `FHE.add`, `FHE.mul`, `FHE.select`, etc. is a fresh handle. Grant access before returning or storing it.

4. **Never use `ebool` in `if` statements** -- `ebool` is an encrypted handle, not a Solidity `bool`. Use `FHE.select(condition, ifTrue, ifFalse)` for all encrypted conditional logic.

5. **Decryption is multi-transaction** -- `FHE.decrypt(value)` triggers decryption in one tx, then `FHE.getDecryptResult(value)` retrieves the plaintext in a later tx. They cannot happen in the same transaction.

6. **Choose the smallest type** -- use `euint8` for small counters, `euint32` for balances, etc. Don't default to `euint256`.

7. **Use `FHE.allowSender()` over `FHE.allow(value, msg.sender)`** -- it's more gas efficient.

## Access Control Quick Reference

| Function | Purpose | When to Use |
|----------|---------|-------------|
| `FHE.allowThis(value)` | Contract can use value later | Storing to state |
| `FHE.allowSender(value)` | Caller can decrypt/read | Returning or creating for user |
| `FHE.allow(value, addr)` | Specific address gets access | Cross-contract sharing |
| `FHE.allowTransient(value, addr)` | One-transaction access | Temporary operations |

## The Store-and-Grant Pattern

This is the most fundamental pattern. Every function that stores or returns encrypted values follows it:

```solidity
function store(InEuint128 calldata num) public {
    counter = FHE.asEuint128(num);   // 1. Convert input & store
    FHE.allowThis(counter);          // 2. Contract can use it later
    FHE.allowSender(counter);        // 3. Caller can read it
}

function increment(InEuint128 calldata num) public {
    euint128 _num = FHE.asEuint128(num);
    counter = FHE.add(counter, _num);  // New handle from computation
    FHE.allowThis(counter);            // Must re-grant on new handle
    FHE.allowSender(counter);
}

function getCounter() public view returns (euint128) {
    return counter;  // Access already granted in store/increment
}
```

## Encrypted Conditionals with FHE.select

Since `ebool` cannot be used in `if` statements, use `FHE.select` for all branching:

```solidity
// Conditional transfer: only transfer if balance is sufficient
ebool canTransfer = FHE.gte(balance, amount);
euint32 actualAmount = FHE.select(canTransfer, amount, ENCRYPTED_ZERO);
balance = FHE.sub(balance, actualAmount);
```

Both branches of `FHE.select` always execute -- there is no short-circuit evaluation.

## Common Mistakes

| Mistake | Symptom | Fix |
|---------|---------|-----|
| Missing `FHE.allowSender()` | "Access denied" when user reads value | Add `FHE.allowSender(value)` before return |
| Missing `FHE.allowThis()` | Contract can't operate on its own stored data | Add `FHE.allowThis(value)` when storing |
| `if (eboolValue)` | Compilation error | Use `FHE.select(eboolValue, a, b)` |
| `decrypt` + `getDecryptResult` in same tx | Reverts or returns stale data | Split into two separate transactions |
| Tests timing out | Forge tests fail on FHE operations | Add `vm.warp(block.timestamp + 11)` in tests |

## Decryption Workflow

Decryption is always a two-step, multi-transaction process:

```solidity
// Transaction 1: request decryption
function requestDecrypt() external {
    FHE.decrypt(encryptedValue);
}

// Transaction 2: retrieve result (separate tx, usually next block)
function getResult() external view returns (uint32) {
    return FHE.getDecryptResult(encryptedValue);
}

// Safe variant that doesn't revert if not ready:
function tryGetResult() external view returns (uint32 val, bool ready) {
    return FHE.getDecryptResultSafe(encryptedValue);
}
```

## Testing with Foundry

FHE tests extend `CoFheTest` from `@fhenixprotocol/cofhe-mock-contracts`:

```solidity
import {CoFheTest} from "@fhenixprotocol/cofhe-mock-contracts/CoFheTest.sol";

contract MyTest is Test, CoFheTest {
    function test_example() public {
        InEuint128 memory input = createInEuint128(42, address(this));
        contract.store(input);
        assertHashValue(contract.getCounter(), 42);
    }

    // Fuzz testing with overflow prevention
    function test_fuzz(uint128 a, uint128 b) public {
        vm.assume(type(uint128).max - a >= b);
        // ... test logic
    }
}
```

## Cross-Contract Sharing

When contract A needs to share encrypted data with contract B:

```solidity
// In contract A:
FHE.allow(encryptedData, addressOfContractB);

// Contract B can now operate on the data
// Contract B must FHE.allowThis() if it stores the value
```

## Reference Files

Read these files for additional detail as needed:

- **`references/core.md`** -- Complete API reference with all encrypted types, every operation signature, casting between types, encrypted constants pattern, full decryption workflow details, cross-contract permission chains, and debugging guide. Read this when you need the full picture or encounter an unfamiliar FHE function.

- **`references/examples/EncryptedStorage.sol`** -- Canonical example contract showing store/increment/decrement with proper access control. Use as a starting template for new contracts.

- **`references/examples/EncryptedStorage.t.sol`** -- Foundry test example using `CoFheTest`, `createInEuint128`, `assertHashValue`, and fuzz testing with `vm.assume`. Use as a starting template for new tests.

- **`references/examples/EncryptedStorage.s.sol`** -- Foundry deployment script. Use as a template for deploy scripts.
