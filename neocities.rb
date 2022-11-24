#!/usr/bin/env ruby
# Push everything allowed in the current working directory to Neocities,
# using the API key specified in environment variable $NEOCITIES_TOKEN.
# Because the official CLI is not working...
# Written by Frog Chen, 24 Oct 2022.

require 'json'
require 'uri'
require 'digest'
require 'httpclient'

class NeocitiesPusher
  API_URI = URI.parse("https://neocities.org/api/")
  FILE_TYPES = %w(.asc .atom .bin .css .csv .dae .eot .epub .geojson .gif .gltf .htm .html .ico .jpeg .jpg .js .json .key .kml .knowl .less .manifest .markdown .md .mf .mid .midi .mtl .obj .opml .otf .pdf .pgp .png .rdf .rss .sass .scss .svg .text .tsv .ttf .txt .webapp .webmanifest .webp .woff .woff2 .xcf .xml)

  def initialize(api_key = ENV["NEOCITIES_TOKEN"])
    raise "Neocities API key missing" if api_key.nil?
    @http = HTTPClient.new(default_header: {"Authorization" => "Bearer #{api_key}"})
  end

  def get(path, params = {})
    uri = API_URI + path
    uri.query = URI.encode_www_form(params)
    parse_result(@http.get(uri))
  end

  def post(path, args = {})
    parse_result(@http.post(API_URI + path, args))
  end

  def parse_result(response)
    json = JSON.parse(response.body, symbolize_names: true)
    raise "Neocities returned no success: #{response.body}" if json[:result] != "success"
    json
  end

  def push
    puts "Pruning ..."
    response = get "list"
    paths = response[:files].filter_map { |file| file[:path] if !File.exist?(file[:path]) }
    post "delete", "filenames[]" => paths unless paths.empty?

    puts "Diffing ..."
    paths = Dir.glob("**/*").select { |path| !File.directory?(path) && FILE_TYPES.include?(File.extname(path)) }
    unless paths.empty?
      response = post "upload_hash", paths.to_h { |path| [path, Digest::SHA1.file(path).hexdigest] }
      paths.reject! { |path| response[:files][path.to_sym] == true }
    end

    puts "Uploading ..."
    post "upload", paths.to_h { |path| [path, File.open(path)] } unless paths.empty? # leaks but works
  end
end

NeocitiesPusher.new.push if __FILE__ == $0
