require "cli/parser"
require "utils/github"

module Homebrew
  module_function

  def request_bottle_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `request-bottle` <formula>

        Build a bottle for this formula with GitHub Actions.
      EOS
      switch "--ignore-errors",
             description: "Instruct the workflow action to ignore e.g., audit errors and upload bottles if they exist."
      max_named 1
    end
  end

  def head_is_merge_commit?
    Utils.popen_read("git", "log", "--merges", "-1", "--format=%H").chomp == Utils.popen_read("git", "rev-parse", "HEAD").chomp
  end

  def git_user
    Utils.popen_read(Utils.git_path, "log", "-1", "--pretty=%an") if ENV['CI'] && head_is_merge_commit? \
      || ENV["HOMEBREW_GIT_NAME"] \
      || ENV["GIT_AUTHOR_NAME"] \
      || ENV["GIT_COMMITTER_NAME"] \
      || Utils.popen_read(Utils.git_path, "config", "--get", "user.name")
  end

  def git_email
    Utils.popen_read(Utils.git_path, "log", "-1", "--pretty=%ae") if ENV['CI'] && head_is_merge_commit? \
      || ENV["HOMEBREW_GIT_EMAIL"] \
      || ENV["GIT_AUTHOR_EMAIL"] \
      || ENV["GIT_COMMITTER_EMAIL"] \
      || Utils.popen_read(Utils.git_path, "config", "--get", "user.email")
  end

  def request_bottle
    request_bottle_args.parse

    raise FormulaUnspecifiedError if Homebrew.args.named.empty?

    user = git_user.strip
    email = git_email.strip

    odie "User not specified" if user.empty?
    odie "Email not specified" if email.empty?

    formula = Homebrew.args.resolved_formulae.last.full_name
    payload = { formula: formula, name: user, email: email, ignore_errors: Homebrew.args.ignore_errors? }
    data = { event_type: "bottling", client_payload: payload }
    url = "https://api.github.com/repos/Homebrew/linuxbrew-core/dispatches"
    GitHub.open_api(url, data: data, request_method: :POST, scopes: ["repo"])
  end
end
