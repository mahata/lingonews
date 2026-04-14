# frozen_string_literal: true

namespace :news do
  desc "Fetch new articles from NHK RSS, summarize with Copilot SDK, and store bilingual content"
  task update: :environment do
    unless ENV["GITHUB_TOKEN"].present?
      abort "ERROR: GITHUB_TOKEN environment variable is required.\n" \
            "Set it to a GitHub PAT with a Copilot subscription."
    end

    puts "Starting news update..."
    News::Updater.call
    puts "Done."
  end
end
