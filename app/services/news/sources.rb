# frozen_string_literal: true

module News
  module Sources
    Source = Struct.new(:name, :url, keyword_init: true).freeze

    def self.all
      @all ||= load_sources
    end

    def self.reload!
      @all = load_sources
    end

    def self.load_sources
      path = Rails.root.join("config", "news_sources.yml")
      data = YAML.safe_load_file(path)

      data.fetch("sources").map do |entry|
        Source.new(name: entry.fetch("name"), url: entry.fetch("url")).freeze
      end.freeze
    end
    private_class_method :load_sources
  end
end
