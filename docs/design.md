# LMAX Disruptor Cross-Language Benchmark Suite — Design

## Goal

Compare how the same producer/consumer processing pattern — modeled on the
LMAX Disruptor (a pre-allocated ring buffer with sequenced, batchable
handlers, avoiding locks and per-message allocation) — performs across
languages, transport protocols, and wire formats, using a realistic
financial-messaging workload: ISO 20022 **pacs.008.001.08**
(`FIToFICustomerCreditTransferV08`).

Each benchmark app is structurally the same regardless of language:

```
client --(protocol)--> [listener] --publish--> [ring buffer] --> [handler chain] --(protocol)--> client
```

The variables under test are:

1. **Language / runtime**: Java, Go, Rust, Python
2. **Transport protocol**: HTTP/2, HTTP/3 (QUIC), WebSockets
3. **Payload format**: XML, JSON, Protobuf

That's a 4 × 3 × 3 = 36-cell matrix. Not every cell is equally idiomatic
(e.g. Protobuf pairs naturally with gRPC-over-HTTP/2; plain REST XML is more
natural over HTTP/2 than HTTP/3), so the matrix is a superset to prioritize
from, not a mandate that every cell gets a bespoke implementation.

## MVP scope (decided)

First four cells to implement, before expanding further:

| | HTTP/2 + JSON | HTTP/2 + XML |
|---|---|---|
| **Java** | ✅ MVP | ✅ MVP |
| **Go** | ✅ MVP | ✅ MVP |

Rationale:
- **Java, Go first** — Java has the reference LMAX Disruptor implementation;
  Go is the second language to validate the pattern translates to a
  GC'd-but-non-JVM runtime with a different concurrency model (goroutines
  vs. threads) before tackling Rust (no GC) or Python (GIL, the hardest
  case). Rust and Python are deferred, not dropped.
- **JSON and XML first, Protobuf deferred** — both are text-based and
  human-diffable, which matters while the shared schemas and handler
  pipeline are still being shaken out. Protobuf adds a code-generation step
  per language that's easier to bolt on once the pipeline shape is proven.
- **HTTP/2 first, not HTTP/3 or WebSockets** — HTTP/2 has the most mature
  client/server support in both ecosystems (Go's `net/http` has native h2
  support; Java has `HttpClient`/Netty), so it isolates the
  disruptor-and-serialization comparison from transport-stack immaturity.
  HTTP/3 (QUIC library maturity varies a lot per language) and WebSockets
  (different request/reply framing, no built-in HTTP semantics) come next,
  once HTTP/2 numbers exist as a baseline to compare against.

Next tranches, in order: add HTTP/3 and WebSockets to Java+Go (still
JSON/XML) → add Protobuf to all combinations built so far → bring in Rust →
bring in Python last (GIL caveat documented above).

## Why LMAX Disruptor as the pattern under test

The Disruptor pattern isolates the cost of message *processing* from the
cost of message *transport*, by giving every language the same internal
shape: a pre-sized ring buffer, a single writer sequence, and one or more
downstream `EventHandler`s that can run in parallel or in a dependency
chain (e.g. `validate -> apply business rule -> journal -> respond`).
Measuring the same shape across languages isolates how much of the
end-to-end latency/throughput difference is transport-and-serialization
versus runtime/concurrency-model overhead.

Per-language equivalents (none of the non-Java runtimes have an off-the-shelf
LMAX port that's a drop-in equivalent, so this is a deliberate choice per
language, to be finalized when that language's benchmark is built):

| Language | Disruptor-pattern implementation |
|---|---|
| Java | [LMAX Disruptor](https://github.com/LMAX-Exchange/disruptor) (native, reference implementation) |
| Go | Hand-rolled ring buffer over a fixed array + atomics/channels (e.g. modeled on `smartystreets/go-disruptor`), since Go's GC and goroutine scheduler are themselves part of what's under test |
| Rust | A ring-buffer crate (candidates: `disruptor-rs`, `ringbuf`) or hand-rolled equivalent using `crossbeam` primitives |
| Python | Approximated with a `multiprocessing`-shared-memory ring buffer or `asyncio` queue; the GIL means single-process Python cannot match the others' parallel-handler model, and that limitation should be reported as a finding, not hidden |

## Metrics captured per run

- Throughput: messages/sec sustained at steady state
- Latency: p50 / p90 / p99 / p99.9, end-to-end (client send → client receive)
- Warm-up handling: discard first N seconds/messages before measuring
- Resource usage: CPU%, RSS, and (JVM only) GC pause count/duration and
  allocation rate
- Error rate: failed/timed-out requests under load

## Load generation

A separate client harness per protocol drives each benchmark app over a
persistent connection (connection reuse matters — TLS/QUIC handshake cost
should not leak into steady-state numbers). Client and server run in
separate containers (see Deployment below) so client-side resource usage
doesn't contaminate server-side measurements.

## Deployment (decided)

Every benchmark deployment — server and client alike, in every language —
runs in a container. This is not optional per combination; it's the only
deployment mode for this project. Reasons:

- **Equivalent resource allocation across languages.** A container gives
  each benchmark app a fixed, declared CPU and memory limit, so "Java vs.
  Go vs. Rust vs. Python" is a comparison of four processes given the same
  resource envelope, not four processes competing for whatever the host
  happens to have free at the time.
- **Reproducibility.** A pinned base image + declared runtime version
  (JDK/Go/Rust/Python version) means a result recorded in `results/` can be
  re-run later against the same environment, not "whatever was installed
  on the benchmark machine that day."
- **Isolation from the host and from each other.** No two benchmark
  combinations should run on the same host at the same time regardless —
  see Load generation above and the noisy-neighbor note in Build & CI —
  but containers make that isolation enforceable (cgroup limits) rather
  than just a run-book convention.

Concretely: each `benchmarks/<lang>/<protocol>-<format>/` combination gets
its own server Dockerfile, and each protocol gets a shared client
Dockerfile (the load-generator harness is per-protocol, not per
combination — see Load generation above). `results/<run>/env.json` records
the image tag/digest and the container's CPU/memory limits alongside the
host's specs, so a result is traceable back to exactly what ran.

Still open: which orchestration tool drives "start this one container pair,
run the load test, tear down, record results" — see Open Questions.

## Repository layout

```
jenkins-ssm/
  docs/
    design.md              <- this file
  schemas/pacs008/          <- shared wire-format contracts, one message, three encodings
    xsd/                    <- ISO 20022 XML Schema (simplified subset, see schemas/pacs008/README.md)
    json/                   <- JSON Schema equivalent
    proto/                  <- Protobuf equivalent
    samples/                <- one example payload per format, same logical message
  benchmarks/
    java/                   <- Java + LMAX Disruptor implementations
    go/                     <- Go implementations
    rust/                   <- Rust implementations
    python/                 <- Python implementations
  results/                  <- benchmark run outputs (raw + summarized), gitignored data with committed format docs
```

Each `benchmarks/<lang>/` directory will grow its own subfolders per
protocol/format combination as those are built, e.g.
`benchmarks/java/http2-json/`, `benchmarks/java/http3-protobuf/`, sharing
common Disruptor/event code within the language where sensible. Every such
combination directory includes its own server `Dockerfile` (see
Deployment below); client harnesses live one level per protocol and are
shared across the formats/languages they drive.

## Build & CI (future work, stubbed for now)

Each language directory builds independently (Maven/Gradle for Java, Go
modules, Cargo, pip/poetry). CI should matrix over language, running that
language's own unit/build checks; running actual load benchmarks in shared
CI runners is not meaningful (noisy neighbors invalidate latency numbers) —
benchmark runs should happen on dedicated/pinned hardware and have their
results committed under `results/` with the run's environment metadata.

## Open questions / next decisions

- Container orchestration tool: docker-compose per combination vs. a
  single runner script (docker CLI) driving each combination in turn vs.
  something heavier (k8s Job) if this ever needs to run at scale?
- How is "same logical message" enforced across encodings — generate
  JSON Schema and Protobuf from the XSD, or hand-maintain three schemas
  and cross-validate with a shared sample set? (Current scaffold hand-
  maintains three schemas over the same sample data — see
  `schemas/pacs008/README.md`.)
- Statistical rigor: number of repetitions per cell, how outliers/GC
  pauses are reported rather than discarded.
