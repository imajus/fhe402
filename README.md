Decentralized API access marketplace where credentials are enforced by math, not vendor policy.

- [Project Requirements](./docs/Requirements.md)
- [Technical Specification](./docs/Specification.md)
- [Whitepaper](https://disk.majus.org/i/yR03ZF4e5YmJpQ)

## What it does

FHE402 lets vendors deposit their API master key on-chain encrypted under FHE. When a buyer (or their AI agent) pays the smart contract, an access token is derived from that master key. The smart contract performs **computation** over FHE-encrypted data, not just storage and retrieval. The agent carries the resulting token to prove access permission, but no party other than the vendor can recover the underlying secret.

Unlike x402, which requires multiple round-trips per request for discovery, payment, and receipt verification, FHE402 bundles payment and access proof into a single token issuance: one transaction, then zero-overhead API calls for the token's lifetime.

## The problem it solves

1. **Credential leakage.** AI agents need plaintext secrets to call external APIs and those secrets leak through context windows, chat logs, and training pipelines. There is no cryptographic mechanism today for an agent to use a credential it cannot read.
2. **Policy-based enforcement.** Rate limits, expiry, and usage constraints live in vendor databases. Enforced by trust, not mathematics. A single server compromise exposes every issued credential.
3. **Payment friction.** Agentic payment protocols like x402 add latency and complexity that's unacceptable for high-frequency workloads making thousands of calls per hour.

## Diagrams

### High Level Overview

<img width="768" alt="Untitled-2026-03-30-2250" src="https://github.com/user-attachments/assets/9bcab120-9d34-49f7-b17a-e4e1c29d40ba" />

### Data flow diagram

<img width="2030" height="1351" alt="Untitled-2026-03-30-2250-2" src="https://github.com/user-attachments/assets/9574e2da-0d45-4119-86b1-9c96015b6ed0" />

## Challenges we ran into

The central research challenge was selecting an FHE-compatible MAC primitive for on-chain token generation.
We evaluated multiple candidates: 

- HMAC-SHA256 requires bitwise operations that exceed practical FHE circuit depth
- Poseidon hash is designed for ZK-SNARK prime-field arithmetic that maps poorly to TFHE's binary gate model.

This analysis shaped our PoC architecture: vendor-side HMAC derivation today, with a clear path to fully on-chain token generation once a suitable primitive is production-ready.

## Technologies we used

- Fhenix (FHE.sol, CoFHE coprocessor, Threshold Services Network)
- HMAC for key derivation and offline validation
- Solidity + Foundry for smart contract development and testing

Because the FHE layer is built on lattice-based cryptography (TFHE), the confidentiality of on-chain master keys is post-quantum secure.

## What's next for FHE402

1. **Audit log.** Every issuance is recorded on-chain as a keccak256 commitment, creating a tamper-evident audit trail without exposing credentials.
2. **Resale.** Owners can prorate unused API quota and sell remaining access to other buyers without exposing the underlying credential.
3. **DePIN.** A permissionless network of proxy nodes validates tokens locally via HMAC recomputation (sub-millisecond, no blockchain call needed), forwards valid requests to the vendor's real API, and earns per-request USDC fees.
