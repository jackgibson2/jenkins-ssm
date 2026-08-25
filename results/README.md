# Benchmark results

Not yet populated — scaffold placeholder.

Each benchmark run should be committed here as one directory per run, named
`<language>-<protocol>-<format>-<yyyymmdd-hhmm>/`, containing:

- `env.json` — host hardware/OS, plus per-container details: image
  tag/digest, declared CPU/memory limits, and language/runtime version
  baked into that image (all deployments are containerized — see
  `../docs/design.md` Deployment section), so results are only compared
  across equivalent environments
- `raw/` — raw per-request latency samples
- `summary.json` — throughput, p50/p90/p99/p99.9 latency, error rate, and
  (JVM only) GC pause stats, as defined in `../docs/design.md`

See `../docs/design.md` for the metrics definitions and open questions on
statistical rigor (repetitions, warm-up, outlier handling).
