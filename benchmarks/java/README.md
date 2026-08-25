# Java benchmarks

Not yet implemented — scaffold placeholder.

Planned: one implementation per protocol/format combination under test,
each using the [LMAX Disruptor](https://github.com/LMAX-Exchange/disruptor)
(the reference implementation of the pattern) as the internal event
processing pipeline. See `../../docs/design.md` for the overall approach
and `../../schemas/pacs008/` for the shared message contract.

## Build order (see `../../docs/design.md` MVP scope)

1. `http2-json/` and `http2-xml/` — **MVP, build these first**
2. `http3-json/`, `http3-xml/`, `ws-json/`, `ws-xml/`
3. `http2-protobuf/`, `http3-protobuf/`, `ws-protobuf/`

Expected layout once implementations land:

```
java/
  disruptor-common/     <- shared ring buffer setup, event types, handler chain
  http2-json/            <- includes its own server Dockerfile (all deployments are containerized)
  http2-xml/              <- includes its own server Dockerfile
  http2-protobuf/
  http3-json/
  http3-xml/
  http3-protobuf/
  ws-json/
  ws-xml/
  ws-protobuf/
```
