class NvimNightly < Formula
  desc "Ambitious Vim-fork focused on extensibility and agility (nightly prebuilt build)"
  homepage "https://neovim.io/"
  # bump: fixed-url
  # The `nightly` tag moves every night: the URLs never change, only the
  # version and the checksums do. The version comes from the release notes.
  version "0.13.0-dev-1630"
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
      sha256 "2ae199d86074936ae8bce8aa39c011b358006072e651801e2d0dfe0e831c9cf8"
    end
    on_intel do
      url "https://github.com/neovim/neovim/releases/download/nightly/nvim-macos-x86_64.tar.gz"
      sha256 "c816406bf0a978e058760dfb8b40ea5a68de710867c996327bd35db435c6bb27"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-arm64.tar.gz"
      sha256 "4a390dec46f24a0b7868a474512c698120e6da31907faa54df12cb0baa9973d1"
    end
    on_intel do
      url "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz"
      sha256 "82d176c215116f96d73c7ffbb788cbac9574507b1191a81f072b7215a2876ef2"
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
