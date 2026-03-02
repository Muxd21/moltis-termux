#!/data/data/com.termux/files/usr/bin/bash
set -e

export PATH="/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/sbin:$PATH"
export PREFIX="/data/data/com.termux/files/usr"
export HOME="/data/data/com.termux/files/home"
export TMPDIR="$PREFIX/tmp"

# Build flags for node-pty on Termux/Bionic
export GYP_DEFINES="OS=linux android_ndk_path=$PREFIX"
export CPPFLAGS="-I$PREFIX/include"
export CXXFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib"
export CC=clang
export CXX=clang++

echo "=== Building node-pty for Termux Bionic ==="
echo "GYP_DEFINES=$GYP_DEFINES"
echo "PREFIX=$PREFIX"

# Try @vscode/node-pty first, then node-pty
if npm install -g @vscode/node-pty 2>&1; then
    echo "=== @vscode/node-pty installed ==="
    GLOBAL_PTY="$(npm root -g)/@vscode/node-pty/build/Release/pty.node"
elif npm install -g node-pty 2>&1; then
    echo "=== node-pty installed ==="
    GLOBAL_PTY="$(npm root -g)/node-pty/build/Release/pty.node"
else
    echo "=== BOTH FAILED ==="
    exit 1
fi

if [ -f "$GLOBAL_PTY" ]; then
    echo "=== pty.node built at: $GLOBAL_PTY ==="
    
    # Copy to the Antigravity server
    SD="$HOME/.antigravity-server/bin/1.18.4-c19fdcaaf941f1ddd45860bfe2449ac40a3164c2"
    
    for PTY_ROOT in "node_modules/node-pty" "node_modules/@vscode/node-pty"; do
        PTY_DIR="$SD/$PTY_ROOT/build/Release"
        if [ -d "$PTY_DIR" ]; then
            [ -f "$PTY_DIR/pty.node" ] && [ ! -f "$PTY_DIR/pty.node.original" ] && \
                mv "$PTY_DIR/pty.node" "$PTY_DIR/pty.node.original"
            cp "$GLOBAL_PTY" "$PTY_DIR/pty.node"
            echo "=== Grafted pty.node to $PTY_ROOT ==="
        fi
    done
    
    # Also ensure the node binary is a proper wrapper
    NODE_BIN="$SD/bin/node"
    if [ -L "$NODE_BIN" ] || ! head -1 "$NODE_BIN" 2>/dev/null | grep -q bash; then
        rm -f "$NODE_BIN"
        cat <<'WRAPPER' > "$NODE_BIN"
#!/data/data/com.termux/files/usr/bin/bash
PREFIX="/data/data/com.termux/files/usr"
export LD_PRELOAD="$PREFIX/lib/libtermux-exec.so"
export PATH="$PREFIX/bin:$PATH"
export SHELL="$PREFIX/bin/bash"
export TERM="${TERM:-xterm-256color}"
export COLORTERM="truecolor"
export TMPDIR="$PREFIX/tmp"
export TMP="$PREFIX/tmp"
export TEMP="$PREFIX/tmp"
exec "$PREFIX/bin/node" "$@"
WRAPPER
        chmod +x "$NODE_BIN"
        echo "=== Node wrapper installed ==="
    fi
    
    # Kill the running server so it restarts with new pty.node
    pkill -f antigravity-server 2>/dev/null || true
    echo "=== Server killed, will restart on next VS Code connect ==="
    echo "=== ALL DONE ==="
else
    echo "=== FAILED: pty.node not found ==="
    exit 1
fi
