# jenkins-ssm

A cross-language benchmark suite for a message-processing pattern modeled
on the LMAX Disruptor, comparing Java, Go, Rust, and Python across
transport protocols (HTTP/2, HTTP/3, WebSockets) and payload encodings
(XML, JSON, Protobuf) of an ISO 20022 `pacs.008` (FIToFICustomerCreditTransfer)
message.

- [`docs/design.md`](docs/design.md) — architecture, test matrix, metrics, open questions
- [`schemas/pacs008/`](schemas/pacs008/) — the shared message contract (XSD/JSON Schema/Protobuf + samples)
- [`benchmarks/`](benchmarks/) — per-language implementations (Java, Go, Rust, Python — not yet implemented)
- [`results/`](results/) — benchmark run outputs

Status: scaffolding only. No benchmark code has been implemented yet.
