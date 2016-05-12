#!/usr/bin/env ruby

require 'net/http'
require 'uri'

class Extracter
  TITLE_REGEXP = %r{<title>(?<title>.*)</title>}m
  GITHUB_REGEXP = %r{https://github.com/(?<repo>[^/]+/[^/]+)/(?:issues|pull)/(?<id>\d+)(?<path>/.*)?}

  # @param url [String]
  def initialize(url)
    @url = url
  end

  # @return [true, false]
  def extracted?
    !title.nil?
  end

  # @return [String, nil]
  def markdown_title
    "[#{extracted? ? title : 'Unknown'}](#{@url})"
  end

  # @return [String]
  def title
    if match = GITHUB_REGEXP.match(@url)
      "#{match[:repo]}##{match[:id]}#{match[:path]}"
    elsif match = TITLE_REGEXP.match(html)
      match[:title].gsub("\n", '')
    else
      nil
    end
  end

  private

  # @return [String]
  def html
    @html ||= fetch(@url)
  end

  # @param url_string [String]
  # @param limit [Integer]
  # @return [String]
  def fetch(url_string, limit = 10)
    url = URI.parse(url_string)
    fail ArgumentError, "Invalid HTTP url: #{url_string}" unless url.is_a?(URI::HTTP)
    fail ArgumentError, 'HTTP redirect too deep' if limit == 0

    res = Net::HTTP.get_response(url)
    case res
    when Net::HTTPSuccess
      res.body
    when Net::HTTPRedirection
      fetch(res['location'], limit - 1)
    else
      res.value
    end
  end
end

url = ARGV[0] || `pbpaste`

begin
  extracter = Extracter.new(url)
  if extracter.extracted?
    puts extracter.markdown_title
    `osascript -e 'display notification "#{extracter.title}" with title "link"'`
  else
    `osascript -e 'display notification "Cannot extract title" with title "link"'`
  end
rescue => e
  `osascript -e 'display notification "#{e.message}" with title "link"'`
end
