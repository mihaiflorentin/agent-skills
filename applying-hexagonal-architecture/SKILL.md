---
name: applying-hexagonal-architecture
description: Describes the hexagonal (ports and adapters) layout with main.go, cmd, config, container, domain, infrastructure and port/{contract,dto,mock}, the lazy service container's rules and the layer import check. Use when designing, planning, building or reviewing code in a project that follows this layout.
disable-model-invocation: true
---

# Hexagonal architecture (ports and adapters)

## Contents
- Folder layout
- The service container
- Why it pays off with agents
- Rules agents follow
- How the workflow uses it
- Enforcing it

Use this guide only in projects that follow this layout (a `layers.rules` file, a `container/` package, or the project docs say so). The workflow skills are architecture-neutral: they apply this guide when the project uses it. The rule underneath it: **dependencies point inward.** Business rules know nothing about databases, HTTP, sockets, queues, frameworks or configuration files. Those reach the core through ports, and the **service container** wires the concrete pieces together.

## Folder layout

```
main.go          builds the service container, sets container.Load, starts the entry point
cmd/             driving adapters: http (router, controllers, middleware, resources), cli
config/          typed configuration: struct, loading (file + env), defaults, validation
container/       the service container: lazy, memoised constructors for every service
domain/          the core: entities, rules, and domain services (the use cases), one folder per area
infrastructure/  driven adapters, one folder per technology, implementing port/contract interfaces
port/
  contract/      interfaces the core needs (VCSInterface, HttpClientInterface, …)
  dto/           plain data that crosses the ports
  mock/          mocks of the contract interfaces, for domain tests
```

| Folder | Holds | May import |
|---|---|---|
| **`domain/<area>/`** | Entities, value objects, pure rules and calculations. Also the **domain services**: the use cases that load through a contract, apply the rules, save through a contract and emit events, with one method per command or handler. Services take their dependencies as constructor parameters: `port/contract` interfaces plus their own `config` sub-struct (`config.Repository`). | `port/`, other `domain/` packages, `config/` (its own sub-struct, as data), `infrastructure/logging`, the standard library. |
| **`port/contract/`** | Interfaces named for the need, ending in `Interface` (`VCSInterface`, `SysOpsInterface`, `StatsdInterface`). No behaviour. | `port/dto/`, the standard library. |
| **`port/dto/`** | Plain structs and error values that cross the contracts. | The standard library. |
| **`port/mock/`** | Hand-written or generated mocks of the contracts, used by domain tests. | `port/`. |
| **`infrastructure/<tech>/`** | Driven adapters such as `git/`, `http/`, `metrics/`, `sys/` and `logging/`. Each implements contract interfaces, maps between DTOs and its wire or storage format, and is built through a `New…(…)` constructor. | `port/`, `config/` (its own settings struct), `infrastructure/logging`, its own libraries. |
| **`cmd/`** | Driving adapters. In `http/`: router, controllers, middleware, resources (response shapes), errors. In `cli/`: commands. A controller decodes input, gets a domain service from the container, calls it and encodes the result. | `container/`, `domain/`, `port/`, `config/`. `infrastructure/logging` is a leaf package that every layer may import. |
| **`config/`** | The `Config` struct with one sub-struct per component, loaded from the config file and env, with defaults and validation. Secrets come from env or a vault only. | The standard library and its parsing libraries. |
| **`container/`** | The **service container**, the composition root. It is the only package that knows every concrete type. | Everything except `cmd/`. |

A UI client mirrors this inside its own tree:
- a pure core (rules mirror, models, folds);
- contract interfaces for the socket and storage;
- adapters that implement them;
- a small container that builds and memoises them;
- views that only render state and send intents.

## The service container

`container/` has one file per layer and one struct per layer, embedded in `ServiceContainer`:

```
container/main.go            ServiceContainer{infrastructure, domain, config}, NewServiceContainer(), Config(), var Load
container/infrastructure.go  InfrastructureContainer: one field per adapter, typed as its contract interface
container/domain.go          DomainContainer: one field per domain service
```

Every dependency has a **getter on `*ServiceContainer`** that builds the dependency on first use, memoises it, and returns it:

```go
func (s *ServiceContainer) GitClient() contract.VCSInterface {
	if s.infrastructure.gitClient != nil {
		return s.infrastructure.gitClient
	}
	client, err := git.NewGitClient(s.Config().Git.SSHKeyPath, s.SysOps())
	if err != nil {
		panic(fmt.Sprintf("Cannot access client. Reason %s", err))
	}
	s.infrastructure.gitClient = client
	return s.infrastructure.gitClient
}
```

Container rules:

1. **Infrastructure getters return the contract interface**, never the concrete type. Domain getters return the domain service.
2. **A getter reads its dependencies through other getters** (`s.SysOps()`, `s.Config()`), never through fields (`s.infrastructure.sysOps`). A field can still be nil when the dependency hasn't been built yet. The getter call builds it, which also makes construction order irrelevant.
3. **Config comes from `s.Config()`** and is passed into constructors as the component's sub-struct (`config.Repository`, `config.StatsD`). A service or adapter receives only its own sub-struct, never the whole `*config.Config`, and never calls `config.NewConfig()` itself.
4. **Fail fast at wiring time.** A required adapter that can't be built panics with the reason. An optional one (metrics, say) logs and falls back to a no-op implementation of its contract.
5. **One container per process.** `main.go` builds it with `NewServiceContainer()` and assigns `container.Load`. Entry points and controllers reach services through `container.Load.<Service>()`.
6. **Tests don't use `container.Load`.** Domain tests construct the service directly with `port/mock` implementations. Integration tests build a fresh `NewServiceContainer()` and may pre-set a field to inject a fake.
7. **Concurrency.** Getters are not goroutine-safe. Build everything long-lived in `main.go` before starting servers and goroutines (call the getters once). Otherwise guard each getter with `sync.Once`.
8. **New dependency checklist:**
   1. Add the interface in `port/contract/`.
   2. Add the adapter in `infrastructure/<tech>/`, with a `New…` constructor.
   3. Add a field in `InfrastructureContainer` or `DomainContainer`.
   4. Add the getter.
   5. Add the config sub-struct if the dependency needs settings.
   6. Add a mock in `port/mock/`.

## Why it pays off with agents

- **Small, predictable diffs.** A rule change touches one `domain/<area>` package and its tests. A technology change touches one `infrastructure/<tech>` folder and one container getter. Reviewers read less.
- **Fast, deterministic domain tests.** Services built with `port/mock` dependencies need no database and no network, so agents can run them on every commit.
- **One place for wiring.** "Where does X get built and with what?" has one answer: the container getter. Agents find it with one grep.
- **Mechanical enforcement.** The import rules below are checked by a script.

## Rules agents follow

1. A new rule or calculation goes in `domain/<area>/` first, with tests. A domain service calls it.
2. If a service needs something external, add a `port/contract` interface named for the need, an `infrastructure/<tech>` adapter, a container field and getter, and a `port/mock`. Follow the checklist above.
3. `domain/` never imports `infrastructure/` (except `infrastructure/logging`), `container/` or `cmd/`. It may import `config/` only for its own sub-struct type (pure data, passed in by the container), and `infrastructure/logging`. It never touches the network, the filesystem, a database driver, a framework or the wall clock directly. Time comes in as an argument or through a clock contract.
4. `port/` never imports `domain/`, `infrastructure/`, `cmd/`, `config/` or `container/`.
5. Adapters in `infrastructure/` and controllers in `cmd/` hold no business rules. An adapter talks to its technology. A controller decodes, calls one service and encodes.
6. Cross-cutting concerns (logging, metrics, retries) are decorators that implement the same contract, wrapped in the container getter, or middleware in `cmd/http/middleware`.
7. Only `main.go`, `cmd/` and tests that build their own container import `container/`.

## How the workflow uses it

- **`/writing-specs`.** The spec's "Data and contracts" section names the contracts a feature needs. Tables, endpoints and config keys are adapter or config details, not rules.
- **`/planning-slices`.** For each task, the plan's contracts list the new `port/contract` interfaces and DTOs, `domain/` packages and services, `infrastructure/` adapters, container getters, `cmd/` routes or commands, and `config/` sub-structs. A task that puts a rule in an adapter or a controller is a plan defect.
- **`/implementing-plans`.** Each task goes in this order:
  1. `port/` (contract, DTO, mock);
  2. `domain/` (rules, then the service, tested with mocks);
  3. `infrastructure/` (integration-tested);
  4. `config/`;
  5. `container/` (getter);
  6. `cmd/` (route or command).
- **`/reviewing-plans`.** Reviewers run `scripts/check-layers.sh` first. They flag dependency-direction violations, rules in `infrastructure/` or `cmd/`, getters that read fields instead of getters, infrastructure getters returning concrete types, `container/` imported by `domain/`, and services that receive the whole `*config.Config` instead of their sub-struct.

## Enforcing it

Put this at `layers.rules` in the repository root. Each line reads "packages under the first prefix must not import the second".

```
# from            must-not-import
domain            infrastructure
domain            cmd
domain            container
port              domain
port              infrastructure
port              cmd
port              config
port              container
infrastructure    cmd
infrastructure    container
infrastructure    domain
config            domain
config            port
config            infrastructure
config            cmd
config            container
# shared leaf: every layer may log
allow domain      infrastructure/logging
allow port        infrastructure/logging
allow config      infrastructure/logging
```

`infrastructure/logging` (through the `allow` lines) and `config/` sub-structs are allowed on purpose.

Then run `scripts/check-layers.sh` from the module root. It exits non-zero with one `VIOLATION:` line per bad import, so it can also go in the project's gate.

For TypeScript, express the same table with eslint import-boundary rules (for example `eslint-plugin-boundaries`).
