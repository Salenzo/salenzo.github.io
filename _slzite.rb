#!/usr/bin/env ruby
#encoding: utf-8
#author: satgo1546

require 'io/console'
require 'kramdown'
require 'kramdown-parser-gfm'
require 'fileutils'
require 'pathname'

class UIErrorMessage < RuntimeError
end

def apply_template(template, contents, dest_filename)
  r = template.chomp + "\n"
  nil while r.gsub!(/^\s*#include\s+[<"](.+)[>"]\s*$/) { File.read("src/modules/#{$1}") }
  r.gsub!(/(href|src)=\"\/\/(.*?)\"/i) { "%s=\"https://%s\"" % [$1, $2] }
  r.gsub!(/(href|src)=\"\/(.*?)\"/i) { "%s=\"%s\"" % [$1, Pathname.new($2).relative_path_from(Pathname.new(File.dirname(dest_filename)))] }
  r.sub!(/^\s*#pragma\s+CONTENTS\s*$/, contents)
end

def generate
  if /ref: refs\/heads\/(master|gh-pages)/ !~ File.read(".git/HEAD").chomp
    puts "It is not currently on the master or gh-pages branch, please note."
    puts "Do note that you are not on branch master or gh-pages."
  end
  main_template = File.read("src/modules/main.html")
  Dir["src/**/*.*"].each do |filename|
    template = File.dirname(filename).sub("src/", "").gsub("/", "_")
    next if template =~ /^modules_?/
    template = "src/modules/#{template}.html"
    template = File.exist?(template) ? File.read(template) : main_template
    dest = filename.sub("src/", "")
    FileUtils.mkdir_p(File.dirname(dest))
    case File.extname(filename)
    when ".md", ".markdown"
      puts "Converting marked text #{filename}……"
      File.write(dest.sub(/\.md$/, ".html"), apply_template(template, Kramdown::Document.new(File.read(filename),
                                                            input: "GFM", gfm_quirks: "paragraph_end,no_auto_typographic").to_html, dest))
    when ".scss", ".sass"
      puts "Compiling style sheet #{filename}……"
      if not system "sass", filename, dest.sub(/\.s[ac]ss$/, ".css")
        raise UIErrorMessage.new("Failed to process #{filename} with SASS!")
      end
    when ".html", ".htm"
      puts "Marking text for hypertext #{filename} to applicate template..."
      File.write(dest, apply_template(template, File.read(filename), dest))
    when ".txt"
      puts "Converting text#{filename}……"
      contents = File.read(filename)
      contents.gsub!("&", "&amp;")
      contents.gsub!(/['\"<>]/, {"'" => "&apos;", "\"" => "&quot;", "<" => "&lt;", ">" => "&gt;"})
      contents = "<pre>#{contents}</pre>"
      File.write(dest.sub(/\.txt$/, ".html"), apply_template(template, contents, dest))
    else
      puts "Copying #{filename}……"
      FileUtils.cp(filename, dest)
    end
  end
end

def preview
  if ENV['OS'] == 'Windows_NT'
    system "start .\\index.html"
  else
    puts "Please open manually now index.html。"
  end
end

def upload
  system "git add -A"
  system "git diff-index --quiet HEAD || git commit --quiet -m \"slzite: upload\""
  if not system "git push"
    raise "An error occurred during upload."
  end
end

def check
  if not Dir.exist?(".git")
    Dir.chdir(__dir__)
    puts "The working directory is not at the top of a git repository. Switched to the directory where _slzite.rb is located."
    if not Dir.exist?(".git")
      raise UIErrorMessage.new("The directory where _slzite.rb is located is still not at the top of a git repository. I have nowhere to go, so I stopped.")
    end
  end
  print "Check the command line tool Git..."
  if not /\d+\.\d+\.\d+/ =~ `git --version`
    raise UIErrorMessage.new("It seems that Git is not installed, or I cannot use it. Please make sure that the Git command line program is installed and available globally. ")
  end
  print "\rCheck the command line tool SASS..."
  if not /\d+\.\d+\.\d+/ =~ `sass --version`
    raise UIErrorMessage.new("It seems that SASS is not installed, or I cannot use it. Please make sure that the SASS command line program has been installed and is globally available.")
  end
end

def interface(first_run)
  if first_run
    puts <<~EOF
      \n\rslzite is a tool for generating websites made with Markdown, SASS, and HTML template technology into a set of webpage files that can be viewed directly by the browser.
      Warning: Website contents reside in src/. Files outside may be overwritten by this tool at any time.
    EOF
  end
  
  if RUBY_PLATFORM =~ /win32/  
    system  "cls"
    system  "pause"
  elsif 
    system  "clear"
      system  "pause"
  end  

  puts <<~EOF
    \nPlease choose your operation:
    [1] Preview
    [2] Upload
    [3] Only generate without previewing or uploading
    [4] Start writing a blog post
    [9] How slzite works
    [0] Exit\n
  EOF
  $stdin.getch
end

def run(option)
  case option
  when "1"
    generate
    preview
  when "2"
    generate
    upload
  when "3"
    generate
  when "4"
    filename = Time.now.strftime("src/post/%Y-%m-%d.md")
    if FileTest.exist?(filename)
      raise UIErrorMessage.new("I have written a blog post today, so let’s write it tomorrow.")
    end
    File.write(filename, "")
    puts "Let me guess your favorite editor."
    if ENV['OS'] == 'Windows_NT'
      tasks = `wmic process get ExecutablePath`.force_encoding('BINARY').encode('UTF-8', :undef => :replace, :replace => '').split(/\s+\n+\s+/).map(&:downcase)
      possibilities = tasks.select do |filename|
        %w(atom.exe code.exe gvim.exe emacs.exe scite.exe).include?(File.basename(filename))
      end
      possibilities.uniq!
      if possibilities.length == 1
        system "start", possibilities.first, filename
      else
        possibilities.unshift("notepad.exe")
        puts "You have too many editors! Choose the one you like:"
        possibilities.each_with_index do |task, i|
          puts "[#{i}] #{task}"
        end
        system "start", possibilities[$stdin.gets.chomp.to_i], filename
      end
    else
      system ENV["EDITOR"], filename
    end
  when "9"
    puts <<~EOF
      　　If you are Li Hua, you want to make a static personal website based on GitHub Pages service, but you think Jekyll is too difficult to use, and you don't want to write HTML and CSS directly. You write your self-introduction in src/index.md in the lihua.github.io repository, write the website style in src/stylesheet.scss, make the website navigation bar in src/modules/navbar.html, and write it out Web page template src/modules/main.html:
        <title>Li Hua's personal website</title>
        <link rel="stylesheet" src="/stylesheet.css">
        <body>
          #include "navbar.html"
          <main>
            #pragma CONTENTS
      　　 If your English composition is placed in src/essay/english/001.md, if you want, you can use the template src/modules/essay_english.html instead of src/modules/main.html. slzblog will process the src directory, automatically convert Markdown and SASS files and apply templates. Common links starting with / in the template will also be replaced with relative paths, so that you can directly open the local web page preview. If you want to publish directly, generation, submission, and push can also be done automatically in one go.
      　　 Press any key to continue...
    EOF
    $stdin.getch
  when "0"
    puts "About to exit."
    exit
  else
    puts "Unknown option, please try again."
  end
rescue => exception
  puts "Something happened."
  puts exception.message
  puts exception.backtrace.join("\n") unless exception.is_a?(UIErrorMessage)
  if ARGV[0].nil?
    puts "Press any key to exit……"
    $stdin.getch
  end
end

run(ARGV[0] || interface(true))
run(interface(false)) until ARGV[0]
