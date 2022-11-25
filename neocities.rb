#!/usr/bin/env ruby
# Push everything allowed in the current working directory to Neocities,
# using the API key specified in environment variable $NEOCITIES_TOKEN.
# Because the official CLI is not working...
# Written by Frog Chen, 24 Oct 2022.
# Updated on 25 Oct 2022: replaced unmaintained httpclient with net/http.

require 'uri'
require 'json'
require 'digest'
require 'net/http'

class NeocitiesPusher
  API_URI = URI.parse("https://neocities.org/api/")
  FILE_TYPES = %w(.asc .atom .bin .css .csv .dae .eot .epub .geojson .gif .gltf .htm .html .ico .jpeg .jpg .js .json .key .kml .knowl .less .manifest .markdown .md .mf .mid .midi .mtl .obj .opml .otf .pdf .pgp .png .rdf .rss .sass .scss .svg .text .tsv .ttf .txt .webapp .webmanifest .webp .woff .woff2 .xcf .xml)

  def initialize(api_key = ENV["NEOCITIES_TOKEN"])
    raise "Neocities API key missing" if api_key.nil?
    @header = {"Authorization" => "Bearer #{api_key}"}
  end

  def get(path, params = {})
    uri = API_URI + path
    uri.query = URI.encode_www_form(params)
    parse_result(Net::HTTP.get_response(uri, @header))
  end

  def post(path, params = {})
    uri = API_URI + path
    request = Net::HTTP::Post.new(uri, @header)
    request.set_form(params, "multipart/form-data")
    parse_result(Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == "https") { |http| http.request(request) })
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
