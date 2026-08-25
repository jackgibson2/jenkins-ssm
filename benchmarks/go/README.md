# Go benchmarks

Not yet implemented — scaffold placeholder.

Planned: one implementation per protocol/format combination under test,
using a hand-rolled ring-buffer/Disruptor-pattern equivalent (Go has no
canonical LMAX port; candidates and tradeoffs are discussed in
`../../docs/design.md`). See `../../schemas/pacs008/` for the shared
message contract.

Expected layout once implementations land:

```
go/
  disruptor/             <- shared ring buffer, event types, handler chain
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
