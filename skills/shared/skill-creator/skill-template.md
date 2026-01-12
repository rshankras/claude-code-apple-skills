# Basic Skill Template

Template for creating simple, self-contained skills.

## Template Structure

```markdown
---
name: skill-name
description: Brief description of what the skill does and when to use it. Keep it to 1-2 sentences that clearly explain the purpose.
allowed-tools: [Read, Write, Edit]
---

# Skill Name

One-paragraph description of what this skill does and its primary purpose.

## When This Skill Activates

Use this skill when the user:
- [Specific trigger phrase or action 1]
- [Specific trigger phrase or action 2]
- [Specific trigger phrase or action 3]
- [Additional triggers as needed]

## Process

### 1. [First Step Name]

- Clear instruction about what to do first
- What to check or verify
- Expected outcomes or decisions

### 2. [Second Step Name]

- Instructions for the second step
- What data to gather or analyze
- How to process the information

### 3. [Third Step Name]

- Instructions for the third step
- How to synthesize findings
- What to prepare for output

### 4. Output Format

How to present results to the user:

#### [Section 1 Name]
- Format for first section
- What information to include

#### [Section 2 Name]
- Format for second section
- Structure and content

#### [Section 3 Name]
- Format for third section
- Final recommendations or next steps

## Checklist

Use this checklist to ensure completeness:

### [Category 1]
- [ ] Check item 1
- [ ] Check item 2
- [ ] Check item 3

### [Category 2]
- [ ] Check item 4
- [ ] Check item 5
- [ ] Check item 6

## Examples

### Example 1: [Scenario Name]

**Input:**
```
[Example input or code]
```

**Expected Output:**
```
[Example output format]
```

### Example 2: [Another Scenario]

**Input:**
```
[Another example]
```

**Expected Output:**
```
[Corresponding output]
```

## Tips

- [Helpful tip 1]
- [Helpful tip 2]
- [Best practice 1]
- [Best practice 2]

## References

- [Link to relevant documentation]
- [Link to related resources]
- [Internal file references if any]

## Notes

- Additional context or considerations
- Edge cases to be aware of
- Limitations of the skill
```

## Fill-In Guide

When using this template:

### name
Use kebab-case (lowercase with hyphens):
- ✅ `code-reviewer`
- ✅ `test-generator`
- ❌ `CodeReviewer`
- ❌ `code_reviewer`

### description
Keep it concise (1-2 sentences):
- Start with what the skill does
- End with when to use it
- Example: "Reviews Swift/iOS code for best practices and common issues. Use when performing code quality checks or refactoring."

### allowed-tools
Choose appropriate tools:
- **Read-only**: `[Read, Glob, Grep]`
- **Code changes**: `[Read, Write, Edit]`
- **Full access**: `[Read, Write, Edit, Glob, Grep, Bash]`
- **Web research**: `[Read, WebFetch]`

### When This Skill Activates
List specific phrases or situations:
- User says "review my code"
- User mentions "best practices"
- User asks "how can I improve this?"

### Process Steps
Break down the workflow:
1. What to do first
2. What to do second
3. How to synthesize
4. How to output

### Checklist
Create actionable items:
- Each item should be verifiable
- Group related items
- Use clear, specific language

### Examples
Provide concrete examples:
- Show input and output
- Use realistic scenarios
- Cover common use cases

## When to Use This Template

Use the basic skill template when:
- ✅ Skill has a single, focused purpose
- ✅ Process can be described in <400 lines
- ✅ No extensive reference material needed
- ✅ Examples fit within the main file
- ✅ Checklist is concise

**Don't use when:**
- ❌ Skill needs extensive checklists (>50 items)
- ❌ Multiple distinct topics/categories
- ❌ Lots of code examples
- ❌ Complex reference material

For complex skills, use the **complex-skill-template.md** instead.

## Example Usage

Here's a filled-out example:

```markdown
---
name: function-documenter
description: Generates comprehensive documentation for Swift functions including parameter descriptions, return values, and usage examples. Use when documenting code or improving API documentation.
allowed-tools: [Read, Write, Edit]
---

# Function Documenter

Automatically generates comprehensive documentation for Swift functions.

## When This Skill Activates

Use this skill when the user:
- Asks to "document this function"
- Mentions "add documentation"
- Requests "generate docs for this code"
- Wants to improve API documentation

## Process

### 1. Analyze Function Signature

- Read the function signature
- Identify all parameters and their types
- Determine return type
- Note any throws/async keywords

### 2. Understand Functionality

- Read function implementation
- Identify the primary purpose
- Note any side effects
- Understand error conditions

### 3. Generate Documentation

- Write clear summary line
- Document each parameter
- Describe return value
- Note any errors thrown
- Add usage example

### 4. Output Format

Generate documentation in this format:

```swift
/// [One-line summary of what the function does]
///
/// [Detailed description if needed]
///
/// - Parameters:
///   - parameter1: Description of parameter1
///   - parameter2: Description of parameter2
/// - Returns: Description of what is returned
/// - Throws: Description of errors that can be thrown
///
/// Example:
/// ```swift
/// let result = functionName(parameter1: value1, parameter2: value2)
/// ```
func functionName(parameter1: Type1, parameter2: Type2) throws -> ReturnType {
    // implementation
}
```

## Checklist

### Documentation Completeness
- [ ] One-line summary present
- [ ] All parameters documented
- [ ] Return value described
- [ ] Errors documented (if throws)
- [ ] Usage example provided

### Quality Checks
- [ ] Summary is clear and concise
- [ ] Parameter descriptions explain purpose, not just type
- [ ] Example is runnable and realistic
- [ ] Documentation uses proper markdown formatting

## Example

### Input Function

```swift
func calculateTotal(items: [Item], discount: Double) throws -> Double {
    guard !items.isEmpty else {
        throw CalculationError.emptyCart
    }
    let subtotal = items.reduce(0) { $0 + $1.price }
    return subtotal * (1 - discount)
}
```

### Generated Documentation

```swift
/// Calculates the total cost of items after applying a discount.
///
/// Sums up the prices of all items and applies the discount percentage
/// to calculate the final total.
///
/// - Parameters:
///   - items: The items to calculate the total for. Must not be empty.
///   - discount: The discount to apply, as a decimal (e.g., 0.1 for 10%)
/// - Returns: The total cost after discount
/// - Throws: `CalculationError.emptyCart` if items array is empty
///
/// Example:
/// ```swift
/// let items = [Item(price: 10.0), Item(price: 20.0)]
/// let total = try calculateTotal(items: items, discount: 0.1)
/// // total = 27.0 (30.0 - 10%)
/// ```
func calculateTotal(items: [Item], discount: Double) throws -> Double {
    guard !items.isEmpty else {
        throw CalculationError.emptyCart
    }
    let subtotal = items.reduce(0) { $0 + $1.price }
    return subtotal * (1 - discount)
}
```

## Tips

- Keep summary line under 80 characters
- Use imperative mood ("Calculates..." not "This calculates...")
- Provide meaningful examples, not just syntax
- Document what, not how (implementation is visible)

## References

- [Swift Documentation Markup](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_markup_formatting_ref/)

## Notes

- For complex functions, break down the description into sections
- Include edge cases in examples
- Update documentation when function signature changes
```
