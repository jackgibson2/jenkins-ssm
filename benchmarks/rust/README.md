# Rust benchmarks

Not yet implemented — scaffold placeholder.

Planned: one implementation per protocol/format combination under test,
using a ring-buffer/Disruptor-pattern equivalent (candidates: `disruptor-rs`,
`ringbuf`, or a hand-rolled buffer over `crossbeam` primitives — see
`../../docs/design.md`). See `../../schemas/pacs008/` for the shared
message contract.

Expected layout once implementations land:

```
rust/
  disruptor/             <- shared ring buffer, event types, handler chain (crate)
  http2-xml/
  http2-json/
  http2-protobuf/
  http3-xml/
  http3-json/
  http3-protobuf/
  ws-xml/
  ws-json/
  ws-protobuf/
```
(subset of the full matrix to build first is still to be decided — see
Open Questions in the design doc)
