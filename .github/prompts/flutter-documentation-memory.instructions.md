---
description: "Documentation workflows and client communication patterns for Flutter projects"
applyTo: "**/*.md, **/docs/**, **/plan/**"
---

# Flutter Documentation Memory

Best practices and workflows for creating client-facing documentation and technical planning documents in Flutter projects.

## Client Documentation Standards

**Format Preferences**:

- Use plain text (.txt) files for non-technical client documentation
- Keep language formal but accessible (Indonesian formal tapi mudah dipahami)
- Structure with numbered sections for clear navigation
- Include concrete time estimates (days/sprints) for development plans
- Separate technical implementation details from client-facing explanations

**Content Organization**:

- Lead with purpose and benefits rather than technical details
- Use "Alur" (flow) sections to explain implemented processes step-by-step
- Include "Rencana Pengerjaan" (development plan) with realistic time estimates
- Note deferred features explicitly to manage client expectations
- Provide status indicators (✅ COMPLETED, 🚀 READY, etc.)

## Documentation Evolution Pattern

**Phase-Based Documentation Updates**:

- Phase 1: Basic implementation with simple documentation
- Phase 2: Enhanced security features with detailed technical specs
- Documentation Phase: Client-friendly explanations with time estimates

**Successful Pattern Observed (13 September 2025)**:

1. Start with technical implementation documentation
2. Create developer-facing Diátaxis-style docs (Reference + How-to)
3. Transform into client-friendly plain text with formal Indonesian
4. Add concrete time estimates for development phases
5. Update project memory with current progress status

## Time Estimation Guidelines

**Proven Estimates for Authentication Features**:

- Login stability and testing: 3-5 hari / 1 sprint
- Logout cleanup implementation: 2-3 hari
- Basic CRUD operations: 1-2 hari per entity
- Security integrations (encryption, hashing): 3-5 hari

## File Organization Best Practices

**Successful Structure**:

- `/plan/` - Technical implementation plans (markdown)
- `/docs/` - Mixed technical and client documentation
- Plain text (.txt) for client-facing content
- Markdown (.md) for developer reference
- Separate "what's implemented" from "what's planned"
