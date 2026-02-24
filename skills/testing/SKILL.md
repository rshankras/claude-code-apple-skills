---
name: testing
description: TDD and testing skills for iOS/macOS apps. Covers characterization tests, TDD workflows, test contracts, snapshot tests, and test infrastructure. Use for test-driven development, adding tests to existing code, or building test infrastructure.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Testing & TDD Skills

Test-driven development workflows and testing infrastructure for Apple platform apps. Works with both new and existing codebases.

## When This Skill Activates

Use this skill when the user:
- Wants to do TDD (test-driven development) with AI-generated code
- Needs to add tests before refactoring existing code
- Wants to fix a bug using the red-green-refactor cycle
- Needs test infrastructure (factories, mocks, contracts)
- Asks about snapshot/visual regression testing
- Wants to ensure AI-generated code is correct via tests

## Available Skills

### For Existing Codebases

**characterization-test-generator/**
Capture current behavior of existing code before refactoring. Generates tests that document what code actually does (not what it should do), giving you a safety net for AI-assisted refactoring.

**tdd-bug-fix/**
Reproduce-first bug fix workflow. Write a failing test that demonstrates the bug, then fix it. Ensures the bug never regresses — critical when AI generates fixes.

**tdd-refactor-guard/**
Pre-refactor safety checklist. Verifies test coverage exists before allowing AI to touch existing code. Prevents the "refactor without a safety net" problem.

### For New Code

**tdd-feature/**
Red-green-refactor scaffold for new features. Generates the failing test first, then guides implementation to make it pass, then refactors. The core TDD workflow.

**test-contract/**
Protocol/interface test suites. Define the contract (e.g., "any DataStore must handle empty state, single item, 100 items, and errors"), and it generates a test suite any implementation must pass.

### Infrastructure

**snapshot-test-setup/**
SwiftUI visual regression testing using swift-snapshot-testing. Generates snapshot test boilerplate, configuration, and CI integration.

**test-data-factory/**
Test fixture factories for your models. Makes writing tests faster by eliminating boilerplate data setup. Supports Builder pattern and static factory methods.

**integration-test-scaffold/**
Cross-module test harness with mock servers, in-memory stores, and test configuration. For testing networking + persistence + business logic together.

## How to Use

1. Identify whether user is working on **new code** or **existing code**
2. Read the relevant skill's SKILL.md for detailed workflow
3. Detect project context (testing framework, architecture, existing tests)
4. Generate tests following the skill's workflow
5. Verify tests compile and run

## Relationship to test-generator

The `generators/test-generator/` skill generates test boilerplate (unit, integration, UI tests). These testing skills are complementary — they focus on **workflows and methodology** (TDD cycle, characterization testing, contracts) rather than just test file generation.

Cross-reference:
- Use `test-generator` for "add tests to this class"
- Use `testing/tdd-feature` for "I want to TDD this new feature"
- Use `testing/characterization-test-generator` for "I need to safely refactor this"
- Use `testing/tdd-bug-fix` for "fix this bug and make sure it never comes back"
