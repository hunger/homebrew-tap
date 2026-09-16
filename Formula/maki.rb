class Maki < Formula
  desc "Efficient AI coding agent extendable by neovim-like Lua plugins"
  homepage "https://maki.sh"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/tontinton/maki/releases/download/v0.5.5/maki-v0.5.5-aarch64-apple-darwin.tar.gz"
      sha256 "05a7f379204cfc0615f73604b53ec295392c8bb21a63b1c0560e9164521d597c"
    end
    on_intel do
      url "https://github.com/tontinton/maki/releases/download/v0.5.5/maki-v0.5.5-x86_64-apple-darwin.tar.gz"
      sha256 "175d56d894e93c3f71ed1d4ccb9bcdf43a9078e8d4a25b712f43933893c061d0"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/tontinton/maki/releases/download/v0.5.5/maki-v0.5.5-aarch64-unknown-linux-musl.tar.gz"
      sha256 "f376926ef5371bd6d207f9ca2ea4114cc040777098822ec14e839d436e5898aa"
    end
    on_intel do
      url "https://github.com/tontinton/maki/releases/download/v0.5.5/maki-v0.5.5-x86_64-unknown-linux-musl.tar.gz"
      sha256 "059432c5a1811afd7d6fe8efdbb2bc098a3b8fd68cf06542589a40b07313c5fd"
    end
  end

  def install
    bin.install "maki"
  end

  def caveats
    <<~EOS
      maki has a built-in `maki update` command. Do not use it for this
      installation; upgrade with `brew upgrade maki` instead.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/maki --version")
  end
end
