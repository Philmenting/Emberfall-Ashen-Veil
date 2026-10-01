#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
backend_root="${EMBERFALL_BACKEND_ROOT:-$(cd "$project_root/../.android-game-tools/online-backend" && pwd)}"
pg_root="$backend_root/extracted/usr/lib/postgresql/16/bin"
pg_libs="$backend_root/extracted/usr/lib/x86_64-linux-gnu"
pg_data="$backend_root/data"
run_dir="$backend_root/run"
nakama_bin="$backend_root/nakama-3.41.0/nakama"
db_address="postgres@127.0.0.1:5432/nakama_local"
pg_started_here=0
nakama_pid=""

cleanup() {
	if [[ -n "$nakama_pid" ]] && kill -0 "$nakama_pid" 2>/dev/null; then
		kill -INT "$nakama_pid" 2>/dev/null || true
		wait "$nakama_pid" 2>/dev/null || true
	fi
	if [[ "$pg_started_here" == "1" ]]; then
		"$pg_root/pg_ctl" -D "$pg_data" -m fast -w stop >/dev/null 2>&1 || true
	fi
}
trap cleanup EXIT INT TERM

if [[ ! -x "$pg_root/pg_ctl" || ! -x "$pg_root/initdb" || ! -x "$nakama_bin" ]]; then
	echo "Local Nakama/PostgreSQL tools are missing. See docs/ONLINE_TEST.md for the expected developer-only setup." >&2
	exit 1
fi

mkdir -p "$run_dir" "$backend_root/nakama-data"
export LD_LIBRARY_PATH="$pg_libs${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

if [[ ! -f "$pg_data/PG_VERSION" ]]; then
	"$pg_root/initdb" -D "$pg_data" -U postgres --auth-local=trust --auth-host=trust
fi

if ! "$pg_root/pg_isready" -h 127.0.0.1 -p 5432 >/dev/null 2>&1; then
	"$pg_root/pg_ctl" -D "$pg_data" -l "$backend_root/postgres-dev.log" -o "-h 127.0.0.1 -p 5432 -c unix_socket_directories=$run_dir" -w start
	pg_started_here=1
fi

if [[ "$("$pg_root/psql" -h 127.0.0.1 -p 5432 -U postgres -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='nakama_local'")" != "1" ]]; then
	"$pg_root/createdb" -h 127.0.0.1 -p 5432 -U postgres nakama_local
fi

"$nakama_bin" migrate up --database.address "$db_address"

echo "Nakama developer server is available at http://127.0.0.1:7350 (console: http://127.0.0.1:7351)."
echo "The API is bound to loopback. Stop with Ctrl+C."
"$nakama_bin" --name emberfall-dev --database.address "$db_address" --data_dir "$backend_root/nakama-data" --runtime.path "$project_root/server/modules" --runtime.js_entrypoint emberfall.js --console.address 127.0.0.1 --console.port 7351 --socket.address 127.0.0.1 --socket.port 7350 --logger.level INFO &
nakama_pid=$!
wait "$nakama_pid"
