# Python benchmarks

Not yet implemented — scaffold placeholder.

Planned: one implementation per protocol/format combination under test.
Python has no true Disruptor-pattern equivalent under the GIL; the plan is
a `multiprocessing`-shared-memory ring buffer or an `asyncio` queue
approximation, with the GIL's impact on the parallel-handler model called
out explicitly as a finding rather than papered over — see
`../../docs/design.md`. See `../../schemas/pacs008/` for the shared
message contract.

Expected layout once implementations land:

```
python/
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
