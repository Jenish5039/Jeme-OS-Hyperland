#!/usr/bin/env python3
"""
Jeme OS — Storage I/O Benchmark: mq-deadline vs kyber
Measures interactive small-read latency (4KB random reads) while a concurrent
heavy sequential write workload (500MB write burst) is executing.
"""
import os
import time
import threading
import tempfile
from pathlib import Path

BENCH_DIR = Path.home() / ".cache" / "jeme-io-bench"
BENCH_DIR.mkdir(parents=True, exist_ok=True)

WRITE_FILE = BENCH_DIR / "heavy_write.tmp"
READ_FILE = BENCH_DIR / "read_target.tmp"

# Create a 64MB read target file with known data
if not READ_FILE.exists() or READ_FILE.stat().st_size < 64 * 1024 * 1024:
    with open(READ_FILE, "wb") as f:
        f.write(os.urandom(64 * 1024 * 1024))
    os.sync()

write_done = False

def background_writer():
    global write_done
    block = os.urandom(1024 * 1024) # 1MB block
    try:
        with open(WRITE_FILE, "wb") as f:
            for _ in range(300): # 300MB write burst
                f.write(block)
                f.flush()
                os.fdatasync(f.fileno())
                if write_done:
                    break
    except Exception:
        pass

def measure_read_latency(samples=50):
    latencies_ms = []
    file_size = READ_FILE.stat().st_size
    with open(READ_FILE, "rb") as f:
        fd = f.fileno()
        for i in range(samples):
            offset = (i * 1048576) % (file_size - 4096)
            os.lseek(fd, offset, os.SEEK_SET)
            t0 = time.perf_counter()
            _ = os.read(fd, 4096)
            t1 = time.perf_counter()
            latencies_ms.append((t1 - t0) * 1000.0)
            time.sleep(0.01)
    return latencies_ms

def main():
    global write_done
    # Read current scheduler
    sched = "unknown"
    sched_path = Path("/sys/block/nvme0n1/queue/scheduler")
    if sched_path.exists():
        sched = sched_path.read_text().strip()

    print(f"=== NVMe I/O Benchmark ===")
    print(f"Current Scheduler: {sched}")

    # 1. Idle Read Latency
    print("Measuring baseline idle read latency (50 samples)...")
    idle_latencies = measure_read_latency(50)
    avg_idle = sum(idle_latencies) / len(idle_latencies)
    max_idle = max(idle_latencies)
    print(f"  Idle Avg: {avg_idle:.3f} ms | Max: {max_idle:.3f} ms")

    # 2. Read Latency under heavy write load
    print("Starting background heavy write burst (300MB sync writes)...")
    writer_thread = threading.Thread(target=background_writer)
    writer_thread.start()

    time.sleep(0.2) # Allow writer to start saturating queue
    print("Measuring read latency under write pressure...")
    load_latencies = measure_read_latency(50)
    write_done = True
    writer_thread.join()

    avg_load = sum(load_latencies) / len(load_latencies)
    max_load = max(load_latencies)
    p95_load = sorted(load_latencies)[int(len(load_latencies) * 0.95)]

    print(f"  Under Load Avg : {avg_load:.3f} ms")
    print(f"  Under Load p95 : {p95_load:.3f} ms")
    print(f"  Under Load Max : {max_load:.3f} ms")

    # Clean up temp write file
    if WRITE_FILE.exists():
        WRITE_FILE.unlink()

if __name__ == "__main__":
    main()
