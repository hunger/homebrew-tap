class NvimNightly < Formula
  desc "Ambitious Vim-fork focused on extensibility and agility (nightly prebuilt build)"
  homepage "https://neovim.io/"
  # bump: fixed-url
  # The `nightly` tag moves every night: the URLs never change, only the
  # version and the checksums do. The version comes from the release notes.
  version "0.13.0-dev-1953"
  license "Apache-2.0"

  livecheck do
    url :stable
    # Lists all releases (prereleases included); the version is in the nightly release notes.
    strategy :github_releases do |json, regex|
      nightly = json.find { |release| release["tag_name"] == "nightly" }
      nightly&.dig("body")&.then { |body| body[regex, 1] }
    end
    regex(/NVIM v(\d+\.\d+\.\d+-dev-\d+)/i)
  end

  on_macos do
    on_arm do
      url "https://github.com/neovim/neovim/releases/download/nightly/nvim-macos-arm64.tar.gz"
      sha256 "15067e55d07d83f1340f5ce278dbc5234c703485c025375ac8672766ddd4e1d6"
    end
    on_intel do
      url "https://github.com/neovim/neovim/releases/download/nightly/nvim-macos-x86_64.tar.gz"
      sha256 "3bdba4053a27b5acdb29e0d18b95070e71d2466b7118a3da0d38cff1f71405be"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-arm64.tar.gz"
      sha256 "911b4c82077578c3650ccf11a14f7d90368f77c991e1170fd9af18d038de5644"
    end
    on_intel do
      url "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz"
      sha256 "1f1cfa89b8e87343cebc8b2202281e8273cd558e4653787a4e2861f1fe3ec48a"
    end
  end

  def install
    # Keep the whole tree (bin/, lib/, share/) private under libexec so nothing
    # collides with the `neovim` formula; expose only `nvim-nightly`.
    # nvim locates its runtime relative to the real executable path, so a
    # symlink is enough.
    libexec.install Dir["*"]
    bin.install_symlink libexec/"bin/nvim" => "nvim-nightly"
    man1.install_symlink libexec/"share/man/man1/nvim.1" => "nvim-nightly.1"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/nvim-nightly --version")
    (testpath/"in.txt").write "hello\n"
    system bin/"nvim-nightly", "--headless", "-u", "NONE", "-c", "normal! Aworld", "-c", "wq", testpath/"in.txt"
    assert_equal "helloworld\n", (testpath/"in.txt").read
    # The runtime must be found through the symlink.
    assert_match "runtime", shell_output("#{bin}/nvim-nightly --headless -u NONE -c 'echo $VIMRUNTIME' -c q 2>&1")
  end
end
