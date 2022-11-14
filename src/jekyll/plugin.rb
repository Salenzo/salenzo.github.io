class Generator < Jekyll::Generator
  priority :low

  def generate(site)
    # Get and set essential information.
    site.config["jekyll_version"] = Jekyll::VERSION
    markdown_converter = site.find_converter_instance(Jekyll::Converters::Markdown)

    # Add a front matter if the file hasn't provided one.
    markdown_files, site.static_files = site.static_files.partition do |file|
      markdown_converter.matches(file.extname)
    end
    site.pages.concat(markdown_files.map do |file|
      base = file.instance_variable_get("@base")
      dir = file.instance_variable_get("@dir")
      name = file.instance_variable_get("@name")
      Jekyll::Page.new(site, base, dir, name)
    end)

    # Add a default layout if the front matter hasn't specified one.
    [site.pages, site.posts.docs].flatten.each do |document|
      next unless markdown_converter.matches(document.extname)
      # Has the user already specified a default for this layout?
      # Note: We must use `to_liquid`, and not data, to ensure front matter defaults
      next if document.to_liquid.key?("layout")
      document.data["layout"] = "default"
    end
  end
end
