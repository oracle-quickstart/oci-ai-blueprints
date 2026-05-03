# Enterprise RAG Benchmark Report

The E- RAG benchmark report was generated with 2 A100s * 40GB and the nim llm profile id:  089d3c0d578020772271e4637f690b66a5054b68151361ba80df2aff9717aea8 running on 8 GPUs i.e. one BM A100.

## Smoke Tests
- **Passed**: 3 • **Failed**: 0 • **Skipped**: 0 • **Duration**: 24.05s
  - `environment` → blueprint_version=v2.3.0
  - `ingestion` → collection=rag_smoke_tests, documents_ingested=7, ingest_latency_ms=18198.19800602272
  - `test_ingest_and_search_returns_results` → documents_ingested=7, search_latency_ms=68.27510404400527, top_score=0.0, total_results=10
  - `test_streaming_generation_smoke` → chunk_count=3, stream_latency_ms=115.50045711919665

## Accuracy Check
- **Samples**: 2 • **Success rate**: 100.00% • **Avg Coverage**: 0.50 • **Avg Latency**: 332.90 ms

## Load Test
- **Requests**: 40 • **Successes**: 40 • **Failures**: 0
- **Latency (ms)**: avg 216.02, p95 490.24, max 494.26
- **TTFT (ms)**: avg 97.57, p50 90.91, p95 112.86
- **TPOT (ms/token)**: avg 15.766, p50 15.933, p95 17.410

## Ingestion Stress
- **Attempts**: 5 • **Successes**: 5 • **Failures**: 0
- **Latency (ms)**: avg 9391.71, p95 12802.53, max 12802.53

## Generation Benchmark

> **TTFT** (Time to First Token) — wall-clock time from sending the request until the first content token arrives.  
> **TPOT** (Time per Output Token) — average time per generated token after the first: `(total_wall_time − TTFT) ÷ (output_tokens − 1)`.  
> **Latency p95** — 95th-percentile end-to-end response time.

### TTFT & TPOT vs Concurrency

| Conc | Req | ✓ | ✗ | RPS | TTFT avg (ms) | TTFT p50 | TTFT p95 | TPOT avg (ms/tok) | TPOT p95 | Latency p95 (ms) |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 10 | 10 | 0 | 3.09 | 85 | 83 | 115 | 14.310 | 14.930 | 472 |
| 2 | 10 | 10 | 0 | 5.58 | 84 | 85 | 96 | 16.220 | 26.940 | 461 |
| 4 | 10 | 10 | 0 | 10.02 | 98 | 90 | 132 | 16.000 | 17.060 | 524 |

### Pipeline Stage Breakdown (avg ms, SDK-reported)

| Conc | Retrieval | Reranker | LLM TTFT | RAG TTFT | LLM Generation |
|---|---|---|---|---|---|
| 1 | 39 | — | 32 | — | 270 |
| 2 | 36 | — | 37 | — | 298 |
| 4 | 45 | — | 42 | — | 308 |

> **Retrieval** = query embedding + Milvus vector search  
> **LLM TTFT** = LLM-only prefill latency (SDK-reported)  
> **RAG TTFT** = retrieval + reranker + LLM prefill (end-to-end to first token)  
> **LLM Generation** = total time the LLM spent generating tokens

## Ingest Scaling

### intro.md
Size: 578 bytes · Est. tokens: 144

| Concurrency | ✓ | ✗ | Wall (s) | Avg (ms) | P95 (ms) | docs/min |
|---|---|---|---|---|---|---|
| 1 | 1 | 0 | 32.5 | 32279 | 32279 | 1.85 |
| 2 | 2 | 0 | 8.2 | 5701 | 6599 | 14.63 |
| 4 | 4 | 0 | 16.6 | 10051 | 12997 | 14.46 |
| 8 | 8 | 0 | 45.0 | 30381 | 37199 | 10.67 |

### embedded_table.pdf
Size: 192,612 bytes · Est. tokens: 48,153

| Concurrency | ✓ | ✗ | Wall (s) | Avg (ms) | P95 (ms) | docs/min |
|---|---|---|---|---|---|---|
| 1 | 1 | 0 | 6.4 | 5996 | 5996 | 9.36 |
| 2 | 2 | 0 | 10.4 | 7696 | 8788 | 11.54 |
| 4 | 4 | 0 | 18.4 | 11750 | 14790 | 13.04 |
| 8 | 8 | 0 | 58.4 | 43829 | 50789 | 8.22 |

### functional_validation.pdf
Size: 181,736 bytes · Est. tokens: 45,434

| Concurrency | ✓ | ✗ | Wall (s) | Avg (ms) | P95 (ms) | docs/min |
|---|---|---|---|---|---|---|
| 1 | 1 | 0 | 6.6 | 6191 | 6191 | 9.10 |
| 2 | 2 | 0 | 10.0 | 7802 | 9802 | 12.00 |
| 4 | 4 | 0 | 43.4 | 36253 | 38596 | 5.53 |
| 8 | 8 | 0 | 65.4 | 51053 | 59601 | 7.34 |

### multimodal_test.pdf
Size: 133,446 bytes · Est. tokens: 33,361

| Concurrency | ✓ | ✗ | Wall (s) | Avg (ms) | P95 (ms) | docs/min |
|---|---|---|---|---|---|---|
| 1 | 1 | 0 | 6.2 | 5796 | 5796 | 9.67 |
| 2 | 2 | 0 | 10.8 | 8198 | 9192 | 11.11 |
| 4 | 4 | 0 | 41.2 | 34851 | 37992 | 5.83 |
| 8 | 8 | 0 | 65.8 | 47756 | 56603 | 7.29 |

### table_test.pdf
Size: 26,342 bytes · Est. tokens: 6,585

| Concurrency | ✓ | ✗ | Wall (s) | Avg (ms) | P95 (ms) | docs/min |
|---|---|---|---|---|---|---|
| 1 | 1 | 0 | 5.4 | 4991 | 4991 | 11.12 |
| 2 | 2 | 0 | 10.0 | 7300 | 8397 | 12.00 |
| 4 | 4 | 0 | 44.0 | 37302 | 41398 | 5.45 |
| 8 | 8 | 0 | 64.2 | 37978 | 50202 | 7.48 |

### woods_frost.docx
Size: 170,811 bytes · Est. tokens: 42,702

| Concurrency | ✓ | ✗ | Wall (s) | Avg (ms) | P95 (ms) | docs/min |
|---|---|---|---|---|---|---|
| 1 | 1 | 0 | 5.2 | 4798 | 4798 | 11.54 |
| 2 | 2 | 0 | 9.2 | 6605 | 7797 | 13.04 |
| 4 | 4 | 0 | 47.8 | 41002 | 44996 | 5.02 |
| 8 | 8 | 0 | 65.2 | 46270 | 55804 | 7.36 |

### woods_frost.pdf
Size: 254,045 bytes · Est. tokens: 63,511

| Concurrency | ✓ | ✗ | Wall (s) | Avg (ms) | P95 (ms) | docs/min |
|---|---|---|---|---|---|---|
| 1 | 1 | 0 | 5.6 | 5196 | 5196 | 10.72 |
| 2 | 2 | 0 | 9.2 | 7001 | 7998 | 13.04 |
| 4 | 4 | 0 | 45.2 | 38451 | 42395 | 5.31 |
| 8 | 8 | 0 | 63.8 | 41751 | 52600 | 7.52 |

## Retrieval Scaling

| Concurrency | Requests | ✓ | RPS | Avg (ms) | P50 (ms) | P95 (ms) | P99 (ms) |
|---|---|---|---|---|---|---|---|
| 1 | 40 | 40 | 16.97 | 59 | 50 | 58 | 398 |
| 2 | 40 | 40 | 36.31 | 54 | 54 | 62 | 83 |
| 4 | 40 | 40 | 56.88 | 68 | 68 | 84 | 86 |
| 8 | 40 | 40 | 61.49 | 123 | 125 | 158 | 160 |