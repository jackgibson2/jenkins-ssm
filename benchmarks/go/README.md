# Go benchmarks

Not yet implemented — scaffold placeholder.

Planned: one implementation per protocol/format combination under test,
using a hand-rolled ring-buffer/Disruptor-pattern equivalent (Go has no
canonical LMAX port; candidates and tradeoffs are discussed in
`../../docs/design.md`). See `../../schemas/pacs008/` for the shared
message contract.

## Build order (see `../../docs/design.md` MVP scope)

1. `http2-json/` and `http2-xml/` — **MVP, build these first**
2. `http3-json/`, `http3-xml/`, `ws-json/`, `ws-xml/`
3. `http2-protobuf/`, `http3-protobuf/`, `ws-protobuf/`

Expected layout once implementations land:

```
go/
  disruptor/             <- shared ring buffer, event types, handler chain
  http2-json/
  http2-xml/
  http2-protobuf/
  http3-json/
  http3-xml/
  http3-protobuf/
  ws-json/
  ws-xml/
  ws-protobuf/
```
