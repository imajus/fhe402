# Fhenix FHE Skill

AI agent skill that gives Claude expert knowledge of Fully Homomorphic Encryption (FHE) smart contract development on the Fhenix protocol.

## What It Does

When installed, Claude automatically activates this skill when you mention FHE, Fhenix, encrypted contracts, private on-chain computation, or related topics. It provides:

- Complete FHE type system and operation reference
- Access control patterns (`FHE.allow*`) that are critical for correctness
- Encrypted conditional logic with `FHE.select`
- Multi-transaction decryption workflows
- Common mistakes and debugging guidance
- Working contract, test, and deployment templates

## Installation

### Claude Code

```bash
claude install-skill /path/to/fhenix-skill
```

Or manually symlink into your project:

```bash
ln -s /path/to/fhenix-skill .claude/skills/fhenix-fhe
```

### Other AI Platforms

Load `references/core.md` directly into the conversation for a comprehensive FHE reference.

## Usage

Just ask naturally -- the skill triggers automatically:

- "Build me an encrypted voting contract using Fhenix"
- "Create a private ERC20 token with encrypted balances"
- "Review this FHE contract for access control issues"
- "Why am I getting access denied errors on my encrypted values?"
- "Help me write Foundry tests for my FHE contract"

## Structure

```
SKILL.md              -- Skill definition (loaded when triggered)
references/
  core.md             -- Complete FHE API reference (loaded on demand)
  examples/
    EncryptedStorage.sol    -- Example contract
    EncryptedStorage.t.sol  -- Example Foundry tests
    EncryptedStorage.s.sol  -- Example deployment script
```

## Key Concept

> Without `FHE.allow()` = passing a locked box without the key!

Every encrypted value needs explicit access grants. This is the #1 source of bugs in FHE contracts.

## Resources

- [Fhenix Documentation](https://docs.fhenix.zone)
- [Fhenix Discord](https://discord.gg/FuVgxrvJMY)
- [cofhe-contracts](https://github.com/fhenixprotocol/cofhe-contracts)
