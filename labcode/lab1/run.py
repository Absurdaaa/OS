#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import os
import signal
import socket
import subprocess
import sys
import time
from datetime import datetime

import pexpect

def wait_port(host: str, port: int, timeout_s: int = 40) -> bool:
    """等待 host:port 可连接。"""
    t0 = time.time()
    while time.time() - t0 < timeout_s:
        try:
            with socket.create_connection((host, port), timeout=1.0):
                return True
        except OSError:
            time.sleep(0.2)
    return False

def main():
    parser = argparse.ArgumentParser(
        description="自动运行 `make debug` + `make gdb`，并在 GDB 中持续 si 单步，仅保存指令相关输出到文件。"
    )
    parser.add_argument("--workspace", default=".", help="工程根目录（含 Makefile）")
    parser.add_argument("--port", type=int, default=1234, help="QEMU gdbstub 端口（默认 1234）")
    parser.add_argument("--steps", type=int, default=100000, help="si 单步次数（默认 1000）")
    parser.add_argument("--gdb_cmd", default="make gdb", help="启动 GDB 的命令（默认使用你的 make gdb）")
    parser.add_argument("--qemu_cmd", default="make debug", help="启动 QEMU 的命令（默认使用你的 make debug）")
    parser.add_argument("--kill_port_first", action="store_true", help="启动前先清理端口占用（用 fuser/lsof）")
    parser.add_argument("--no_color", action="store_true", help="GDB 禁用颜色，便于日志阅读")
    args = parser.parse_args()

    ws = os.path.abspath(args.workspace)
    os.makedirs(ws, exist_ok=True)

    qemu_log_path = os.path.join(ws, "qemu.log")
    gdb_transcript_path = os.path.join(ws, "gdb_transcript.log")
    gdb_steps_path = os.path.join(ws, "gdb_steps.log")

    # 1) 可选：清理端口占用
    if args.kill_port_first:
        try:
            subprocess.run(f"fuser -k {args.port}/tcp", shell=True, check=False)
        except Exception:
            subprocess.run(f"lsof -ti :{args.port} | xargs -r kill -9", shell=True, check=False)

    # 2) 启动 QEMU（make debug），写实时日志到 qemu.log
    qemu_log = open(qemu_log_path, "w", buffering=1)
    print(f"[INFO] 启动 QEMU: {args.qemu_cmd}")
    qemu_proc = subprocess.Popen(
        args.qemu_cmd,
        cwd=ws,
        shell=True,
        stdout=qemu_log,
        stderr=subprocess.STDOUT,
        preexec_fn=os.setsid,   # 便于整体杀进程组
    )

    # 3) 等待端口就绪
    print(f"[INFO] 等待 gdbstub 端口 {args.port} ...")
    if not wait_port("127.0.0.1", args.port, timeout_s=60):
        print("[ERROR] 端口等待超时。请查看 qemu.log 获取错误原因。", file=sys.stderr)
        try:
            os.killpg(os.getpgid(qemu_proc.pid), signal.SIGTERM)
        except Exception:
            pass
        qemu_log.close()
        sys.exit(1)

    print("[INFO] 端口就绪，启动 GDB 会话并开始记录。")

    # 4) 启动 GDB：用你的 make gdb（进入 gdb 交互）
    gdb_cmd = args.gdb_cmd
    if args.no_color:
        gdb_cmd += " -ex 'set style enabled off'"

    # 打开 GDB 完整转录日志 和 每步指令日志
    gdb_transcript = open(gdb_transcript_path, "w", buffering=1)
    gdb_steps = open(gdb_steps_path, "w", buffering=1)

    child = pexpect.spawn(
        f"bash -lc \"{gdb_cmd}\"",
        cwd=ws,
        encoding="utf-8",
        timeout=10,
        maxread=200_000,
        logfile=gdb_transcript,   # 完整会话日志：所有 GDB 交互都会被记录
    )

    # 等待 GDB 提示符
    try:
        child.expect(r"\(gdb\)\s*")
    except pexpect.TIMEOUT:
        print("[ERROR] 启动 GDB 超时，检查 gdb_transcript.log", file=sys.stderr)
        raise

    # 关闭分页、开启“下一行反汇编显示”，避免输出被 --More-- 截断
    for c in ("set pagination off", "set disassemble-next-line on"):
        child.sendline(c)
        child.expect(r"\(gdb\)\s*")

    # 仅保留“指令相关输出”：每步的 PC 处反汇编 + si 之后的反馈
    def gdb_run_and_capture(cmd: str) -> str:
        child.sendline(cmd)
        child.expect(r"\(gdb\)\s*")
        return child.before  # 返回此命令输出（不含下一个提示符）

    print(f"[INFO] 开始 si 单步 {args.steps} 次，输出写入：{gdb_steps_path}")
    # gdb_steps.write(f"# SI stepping started at {datetime.now().isoformat()}\n")
    # gdb_steps.flush()

    try:
        for i in range(1, args.steps + 1):
            # 当前 PC 的反汇编（便于知道即将执行/刚执行到哪里）
            dis = gdb_run_and_capture("x/i $pc")

            # 单步执行 1 条指令（如果首次加载较慢，适当放宽超时）
            child.sendline("si")
            child.expect(r"\(gdb\)\s*", timeout=10)
            si_out = child.before

            # # 只记录“指令相关输出”
            # ts = datetime.now().strftime("%H:%M:%S.%f")[:-3]
            # gdb_steps.write(f"\n=== STEP {i} @ {ts} ===\n")
            # gdb_steps.write("[x/i $pc]\n")
            # gdb_steps.write(dis.strip() + "\n")
            # gdb_steps.write("[si]\n")
            # gdb_steps.write(si_out.strip() + "\n")
            # gdb_steps.flush()

    except KeyboardInterrupt:
        print("\n[INFO] 收到中断，准备清理并退出。")
    except Exception as e:
        print(f"[ERROR] 单步过程中出错：{e}", file=sys.stderr)
    finally:
        # 关闭 GDB
        try:
            child.sendline("detach")
            child.expect(r"\(gdb\)\s*", timeout=3)
        except Exception:
            pass
        try:
            child.sendline("quit")
            child.close(force=True)
        except Exception:
            pass

        # gdb_steps.write(f"\n# SI stepping ended at {datetime.now().isoformat()}\n")
        # gdb_steps.close()
        gdb_transcript.close()

        # 结束 QEMU
        try:
            os.killpg(os.getpgid(qemu_proc.pid), signal.SIGTERM)
        except Exception:
            pass
        qemu_log.flush()
        qemu_log.close()

    print("[INFO] 完成。日志文件：")
    print(f"  - QEMU 日志:        {qemu_log_path}")
    print(f"  - GDB 转录日志:     {gdb_transcript_path}")
    print(f"  - 步进摘要日志:     {gdb_steps_path}")

if __name__ == "__main__":
    main()
