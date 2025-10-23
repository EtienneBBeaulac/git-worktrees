class GitWorktrees < Formula
  desc "Simple shell helpers for Git worktrees with fzf integration"
  homepage "https://github.com/EtienneBBeaulac/git-worktrees"
  url "https://github.com/EtienneBBeaulac/git-worktrees/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "4be2c0b1a25d3bb026ed623744883e80981b9ff1a7729ea9167be9b4a10cb4c2"
  license "MIT"
  
  head "https://github.com/EtienneBBeaulac/git-worktrees.git", branch: "main"

  depends_on "fzf" => :recommended
  depends_on "git"
  uses_from_macos "zsh"

  def install
    # Install library files to libexec
    libexec.install "scripts/wt"
    libexec.install "scripts/wtnew"
    libexec.install "scripts/wtrm"
    libexec.install "scripts/wtopen"
    libexec.install "scripts/wtls"
    (libexec/"lib").install "scripts/lib/wt-common.zsh"
    (libexec/"lib").install "scripts/lib/wt-discovery.zsh" if File.exist?("scripts/lib/wt-discovery.zsh")
    (libexec/"lib").install "scripts/lib/wt-recovery.zsh" if File.exist?("scripts/lib/wt-recovery.zsh")
    (libexec/"lib").install "scripts/lib/wt-validation.zsh" if File.exist?("scripts/lib/wt-validation.zsh")
    
    # Create executable wrapper scripts in bin (automatically added to PATH)
    %w[wt wtnew wtrm wtopen wtls].each do |cmd|
      (bin/cmd).write <<~EOS
        #!/bin/zsh
        # Homebrew-installed git-worktrees
        export WTRM__SCRIPT_DIR="#{libexec}"
        export WTNEW__SCRIPT_DIR="#{libexec}"
        export WTOPEN__SCRIPT_DIR="#{libexec}"
        export WTLS__SCRIPT_DIR="#{libexec}"
        export WT__SCRIPT_DIR="#{libexec}"
        source "#{libexec}/lib/wt-common.zsh"
        source "#{libexec}/#{cmd}"
        #{cmd} "$@"
      EOS
    end
  end

  def caveats
    <<~EOS
      git-worktrees is now ready to use! Commands are in your PATH:

        wt          # Hub to list, open, create, and manage worktrees
        wtnew       # Create/open a worktree for a new or existing branch
        wtopen      # Open an existing worktree
        wtrm        # Safely remove a worktree
        wtls        # List worktrees with status

      Try it now:
        wt --help

      For more information: https://github.com/EtienneBBeaulac/git-worktrees
    EOS
  end

  test do
    # Test that scripts exist and are valid zsh
    system "zsh", "-n", libexec/"wt"
    system "zsh", "-n", libexec/"wtnew"
    system "zsh", "-n", libexec/"wtrm"
    system "zsh", "-n", libexec/"wtopen"
    system "zsh", "-n", libexec/"wtls"
    system "zsh", "-n", libexec/"lib/wt-common.zsh"
  end
end

