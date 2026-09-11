class CratesLsp < Formula
  desc "Language Server implementation for Cargo.toml"
  homepage "https://github.com/MathiasPius/crates-lsp"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/MathiasPius/crates-lsp/releases/download/v0.4.3/crates-lsp-aarch64-apple-darwin.tar.gz"
      sha256 "ca5c608b7fb90f8bdf5d49a74b67fd9eff4369ad8c1db3bbb63389dba67c8e55"
    end
    on_intel do
      url "https://github.com/MathiasPius/crates-lsp/releases/download/v0.4.3/crates-lsp-x86_64-apple-darwin.tar.gz"
      sha256 "a750e9b52b487592b5c49d86877ec7d54e5701a335f02f5a67cd4c88f3441bfb"
    end
  end

  # Upstream ships only glibc-linked (gnu) Linux binaries; no musl build exists.
  on_linux do
    on_arm do
      url "https://github.com/MathiasPius/crates-lsp/releases/download/v0.4.3/crates-lsp-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "fb6e9df82010e9996ff0895c201355f17359518f788db227f6810b450e594be8"
    end
    on_intel do
      url "https://github.com/MathiasPius/crates-lsp/releases/download/v0.4.3/crates-lsp-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "694e349e217127bf0b9e78d7248d6a041c4893384ef784ed58fbe3af96c0c3d3"
    end
  end

  def install
    bin.install "crates-lsp"
  end

  test do
    # crates-lsp is a stdio language server with no --version output;
    # feed it a malformed message and expect a JSON-RPC error reply.
    output = pipe_output(bin/"crates-lsp", "not a valid lsp message\r\n\r\n")
    assert_match "jsonrpc", output
  end
end
