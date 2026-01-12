---
name: product-development
description: End-to-end product development for iOS/macOS apps. Covers market research, competitive analysis, PRD generation, architecture specs, UX design, implementation guides, testing, and App Store release. Use for product planning, validation, or generating specification documents.
allowed-tools: [Read, Write, Glob, Grep, WebFetch, WebSearch, AskUserQuestion]
---

# Product Development Expert

Comprehensive product development guidance for iOS/macOS apps. This skill orchestrates the entire product lifecycle from idea validation to App Store release.

## When This Skill Activates

Use this skill when the user:
- Has an app idea and wants to validate it
- Needs market research or competitive analysis
- Wants to generate product specifications
- Needs architecture or UX design documents
- Is preparing for App Store submission
- Wants end-to-end product planning

## Available Modules

Read relevant module files based on the user's needs:

### Discovery & Validation

**product-agent/**
AI-powered product discovery and validation.
- Idea validation and assessment
- MVP scoping
- Market opportunity analysis

**market-research/**
Deep market analysis.
- Market sizing (TAM/SAM/SOM)
- Growth trends and maturity
- Entry barriers and distribution channels
- Revenue potential

**competitive-analysis/**
Competitor deep dive.
- Feature comparison matrices
- Pricing analysis
- Strengths/weaknesses
- Differentiation opportunities

### Specification Generation

**prd-generator/**
Product Requirements Document.
- Features and user stories
- Acceptance criteria
- Success metrics

**architecture-spec/**
Technical architecture.
- Architecture pattern selection
- Tech stack decisions
- Data models
- App structure

**ux-spec/**
UI/UX specifications.
- Wireframes and user flows
- Design system definition
- Interaction patterns

**implementation-guide/**
Development roadmap.
- Step-by-step instructions
- Pseudo-code examples
- Implementation priorities

**test-spec/**
QA and testing strategy.
- Unit test coverage
- UI testing plan
- Accessibility testing
- Beta testing strategy

**release-spec/**
App Store preparation.
- Submission guide
- Asset requirements
- Privacy compliance
- Marketing strategy

### Orchestration

**implementation-spec/**
Master orchestrator.
- Generates complete specification package
- Coordinates all role-based agents
- End-to-end spec generation

**WORKFLOW.md**
Product development workflow guide.

## How to Use

1. Identify where user is in product lifecycle
2. Read relevant module SKILL.md for detailed process
3. Generate requested specifications
4. Save outputs to appropriate files

## Example Workflows

**User has new app idea:**
1. Use `product-agent/` for initial validation
2. Run `market-research/` for market sizing
3. Run `competitive-analysis/` for competitor insights
4. Generate PRD with `prd-generator/`

**User wants full spec package:**
1. Use `implementation-spec/` orchestrator
2. It coordinates all spec generators
3. Produces complete documentation set
