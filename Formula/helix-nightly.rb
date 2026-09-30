class HelixNightly < Formula
  desc "Post-modern modal text editor (built from the master branch)"
  homepage "https://helix-editor.com"
  # bump: git-commit https://api.github.com/repos/helix-editor/helix/commits/master
  # bottle: x86_64_linux
  # Pinned to a master commit; the version is that commit's UTC date and time.
  # CI builds a Linux x86_64 bottle and hosts it on this tap's GitHub Releases.
  url "https://github.com/helix-editor/helix/archive/ba40e547426b0f9896c8bdc699a4ab11f2b37dbc.tar.gz"
  version "2026.09.29.0232"
  sha256 "c5e35c68897a0f3793937095d8d9c13340fa18e727a3696ae16fa0edd1d08d23"
  license "MPL-2.0"

  livecheck do
    url "https://api.github.com/repos/helix-editor/helix/commits/master"
    strategy :json do |json|
      date = json.dig("commit", "committer", "date").to_s
      m = date.match(/(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/)
      m && "#{m[1]}.#{m[2]}.#{m[3]}.#{m[4]}#{m[5]}"
    end
  end

  bottle do
    root_url "https://github.com/hunger/homebrew-tap/releases/download/helix-nightly-2026.09.29.0232"
    sha256 cellar: :any, x86_64_linux: "117f1ac567425fef90823533713bbb5615eedd5d47df1bcbc1fb26e6924562a2"
  end

  depends_on "rust" => :build

  def commit
    stable.url[/([0-9a-f]{40})\.tar\.gz/, 1]
  end

  def install
    ENV["HELIX_DEFAULT_RUNTIME"] = libexec/"runtime"
    # Source tarballs have no .git; this makes `hx --version` report the commit.
    ENV["HELIX_NIX_BUILD_REV"] = commit[0, 8]
    system "cargo", "install", *std_cargo_args(path: "helix-term")
    # Expose the binary as `hx-nightly` so it can coexist with the `helix` formula.
    mv bin/"hx", bin/"hx-nightly"
    rm_r "runtime/grammars/sources/"
    libexec.install "runtime"

    # Retarget the completions from `hx` to `hx-nightly` (function names like `_hx` stay).
    inreplace "contrib/completion/hx.bash", /\bhx\b/, "hx-nightly"
    inreplace "contrib/completion/hx.fish", /\bhx\b/, "hx-nightly"
    inreplace "contrib/completion/hx.zsh", /\bhx\b/, "hx-nightly"
    bash_completion.install "contrib/completion/hx.bash" => "hx-nightly"
    fish_completion.install "contrib/completion/hx.fish" => "hx-nightly.fish"
    zsh_completion.install "contrib/completion/hx.zsh" => "_hx-nightly"
  end

  test do
    assert_match "post-modern text editor", shell_output("#{bin}/hx-nightly --help")
    assert_match commit[0, 8], shell_output("#{bin}/hx-nightly --version")

    # `--health` probes the tree-sitter grammar plugins and can hang in CI;
    # just verify the key grammars were installed.
    grammar_dir = libexec/"runtime/grammars"
    grammar_sos = Dir.glob("#{grammar_dir}/*.so").map { |f| File.basename(f) }
    %w[rust python c cpp toml json yaml ini html css markdown xml].each do |lang|
      assert_includes grammar_sos, "#{lang}.so",
        "missing grammar for #{lang}"
    end
  end
end
