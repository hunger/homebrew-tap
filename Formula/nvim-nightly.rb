class NvimNightly < Formula
  desc "Ambitious Vim-fork focused on extensibility and agility (nightly prebuilt build)"
  homepage "https://neovim.io/"
  # bump: fixed-url
  # The `nightly` tag moves every night: the URLs never change, only the
  # version and the checksums do. The version comes from the release notes.
  version "0.13.0-dev-1944"
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
      sha256 "2663a879db6f59e120b42af3a2bedfa1644cd3606a43196f1f524dc4df63f45e"
    end
    on_intel do
      url "https://github.com/neovim/neovim/releases/download/nightly/nvim-macos-x86_64.tar.gz"
      sha256 "f9da155f6d67bddac39b04069b49fb4bf780e0670e38f97b49a2a69d83a1e23c"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-arm64.tar.gz"
      sha256 "38293fc3904465860ccd3f473277177270b70e00ca52d26d8fa85f7f758469d3"
    end
    on_intel do
      url "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz"
      sha256 "b5d9ef2865f7f08b938cc739d97252af44ff18f38f8eb2f467a4e5d044d5bfce"
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
