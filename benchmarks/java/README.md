# Java benchmarks

Not yet implemented — scaffold placeholder.

Planned: one implementation per protocol/format combination under test,
each using the [LMAX Disruptor](https://github.com/LMAX-Exchange/disruptor)
(the reference implementation of the pattern) as the internal event
processing pipeline. See `../../docs/design.md` for the overall approach
and `../../schemas/pacs008/` for the shared message contract.

Expected layout once implementations land:

```
java/
  disruptor-common/     <- shared ring buffer setup, event types, handler chain
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
