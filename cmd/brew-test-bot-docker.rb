#: `test-bot-docker` <formule>...
#:
#:  Build a bottle for the specified formulae using a Docker container.
#:  See `test-bot` for further options accepted by this command.

module Homebrew
  module_function

  def test_bot_docker
    if ENV["BINTRAY_USER"].nil? || ENV["BINTRAY_KEY"].nil?
      raise "Missing BINTRAY_USER or BINTRAY_KEY variables!"
    end

    argv = ARGV.join(" ")
    safe_system "docker", "run", "--name=linuxbrew-test-bot",
      "-e", "BINTRAY_USER", "-e", "BINTRAY_KEY",
      "linuxbrew/linuxbrew",
      "sh", "-c", "brew test-bot #{argv} && ls && brew test-bot --ci-upload && head *.json"

    safe_system "docker", "cp", "linuxbrew-test-bot:/home/linuxbrew", "linuxbrew-test-bot"
    cd "linuxbrew-test-bot" do
      safe_system HOMEBREW_BREW_FILE, "bottle", "--merge", "--write", *Dir["*.json"]
    end

    oh1 "Done!"
    puts <<-EOS.undent
      To clean up, run
        docker rm linuxbrew-test-bot
        rm -rf linuxbrew-test-bot
    EOS
  end
end

Homebrew.test_bot_docker
