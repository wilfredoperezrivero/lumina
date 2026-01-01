# Agents Best Practices

## Overview
- Treat each agent as a small, autonomous service with a single, clear responsibility.
- Keep orchestration logic separate from reasoning/execution logic to make agents composable.
- Prefer declarative configurations (YAML/JSON) for wiring agents together; keep imperative code minimal.

## Clean Architecture Layers
1. **Domain**
   - Define agent goals, capabilities, and shared business rules.
   - Express invariants and policies as pure Dart classes or functions.
   - No framework or IO dependencies.
2. **Application**
   - Coordinate use cases such as `PlanCapsule`, `RouteCustomerIntent`, or `SummarizeContext`.
   - Translate external requests into domain commands and manage workflows.
   - Depends only on the domain layer; keeps orchestration deterministic.
3. **Interface / Infrastructure**
   - Adapters to external APIs (LLMs, vector stores, HTTP services) and platform integrations.
   - Provide abstractions (e.g., `EmbeddingsProvider`, `ConversationStore`) that the application layer consumes.
   - Handle serialization, error mapping, retries, and logging.
4. **Framework / Delivery**
   - Flutter widgets, CLI entrypoints, or cloud functions that expose agent functionality.
   - Compose application-layer use cases and translate UI or transport events into commands.

## Best Practices
- **SRP First**: Each agent encapsulates one intent; delegate extra work to sub-agents instead of branching logic.
- **Contract-Driven Design**: Define clear input/output contracts using DTOs or typed maps. Version them to avoid breaking changes.
- **State Isolation**: Keep agent state ephemeral; persist long-lived data in repositories managed by the infrastructure layer.
- **Observability**: Emit structured logs with correlation IDs (`conversationId`, `agentRunId`). Capture decisions, prompts, and tool outputs for auditing.
- **Security**: Validate all external inputs before they enter the domain layer. Mask secrets in logs and secure prompt templates.
- **Testing Strategy**: Use unit tests for domain logic, scenario tests for application workflows, and contract tests for infrastructure adapters. Mock LLM calls.
- **Prompt Hygiene**: Store prompts alongside version metadata. Use templating with explicit variables; validate that prompts stay within token budgets.
- **Performance**: Cache deterministic computations (embeddings, static context). Use asynchronous execution for IO-bound steps.
- **Failure Recovery**: Implement retry policies with exponential backoff. Surface actionable errors to the orchestrator.

## Folder Conventions
- `lib/domain/agents`: Domain models, policies, and value objects.
- `lib/application/agents`: Use cases, orchestrators, and planners.
- `lib/infrastructure/agents`: API clients, repositories, and platform adapters.
- `lib/presentation/agents`: UI bindings, controllers, and entrypoints.

## Collaboration Checklist
- Document new agents in `lumina.md` or the README with purpose, dependencies, and owner.
- Provide example payloads and expected outputs for each agent contract.
- Keep migrations and infrastructure changes in sync with the agent release cycle.
- Run the relevant test suites before merging (`flutter test`, integration harnesses).

## References
- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/) (apply layered boundaries rigorously).
- Internal onboarding notes in `lumina.md` for project-specific conventions.
