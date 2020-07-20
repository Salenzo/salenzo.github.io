#!/usr/bin/env ruby
#encoding: utf-8
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
  r.gsub!(/(href|src)=\"\/(.*?)\"/i) { "%s=\"%s\"" % [$1, Pathname.new($2).relative_path_from(Pathname.new(File.dirname(dest_filename)))] }
  r.sub!(/^\s*#pragma\s+CONTENTS\s*$/, contents)
end

def generate
  if /ref: refs\/heads\/(master|gh-pages)/ !~ File.read(".git/HEAD").chomp
    puts "当前不在master或gh-pages分支上，请注意。"
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
      puts "正在转换标记文本#{filename}……"
      File.write(dest.sub(/\.md$/, ".html"), apply_template(template, Kramdown::Document.new(File.read(filename), input: "GFM", gfm_quirks: "paragraph_end,no_auto_typographic").to_html, dest))
    when ".scss", ".sass"
      puts "正在编译样式表#{filename}……"
      if not system "sass", filename, dest.sub(/\.s[ac]ss$/, ".css")
        raise UIErrorMessage.new("用SASS对#{filename}处理失败了！")
      end
    when ".html", ".htm"
      puts "正在为超文本标记文本#{filename}应用模板……"
      File.write(dest, apply_template(template, File.read(filename), dest))
    when ".txt"
      puts "正在转换文本#{filename}……"
      contents = File.read(filename)
      contents.gsub!("&", "&amp;")
      contents.gsub!(/['\"<>]/, {"'" => "&apos;", "\"" => "&quot;", "<" => "&lt;", ">" => "&gt;"})
      contents = "<pre>#{contents}</pre>"
      File.write(dest.sub(/\.txt$/, ".html"), apply_template(template, contents, dest))
    else
      puts "正在复制#{filename}……"
      FileUtils.cp(filename, dest)
    end
  end
end

def preview
  if ENV['OS'] == 'Windows_NT'
    system "start .\\index.html"
  else
    puts "请现在手动打开index.html。"
  end
end

def upload
  system "git add -A"
  system "git diff-index --quiet HEAD || git commit --quiet -m \"slzite: upload\""
  if not system "git push"
    raise "上传时发生错误。"
  end
end

def check
  if not Dir.exist?(".git")
    Dir.chdir(__dir__)
    puts "工作目录不在一个git存储库顶端。已切换到_slzite.rb所在目录。"
    if not Dir.exist?(".git")
      raise UIErrorMessage.new("_slzite.rb所在目录仍不是一个git存储库顶端。我无路可退，故停止。")
    end
  end
  print "检查命令行工具Git……"
  if not /\d+\.\d+\.\d+/ =~ `git --version`
    raise UIErrorMessage.new("似乎没有安装Git，或者我不能使用。请确认已经安装Git命令行程序并全局可用。")
  end
  print "\r检查命令行工具SASS……"
  if not /\d+\.\d+\.\d+/ =~ `sass --version`
    raise UIErrorMessage.new("似乎没有安装SASS，或者我不能使用。请确认已经安装SASS命令行程序并全局可用。")
  end
end

def interface(first_run)
  if first_run
    puts <<~EOF
      \r欢迎！slzite是将使用Markdown、SASS、HTML模板技术制作的网站生成为浏览器可以直接查看的网页文件集的工具。
      警告：网站内容在src目录中。该目录外的内容会随时被本工具覆盖！
      slzite is a tool for generating websites made with Markdown, SASS, and HTML template technology into a set of webpage files that can be viewed directly by the browser.
      Warning: Website contents reside in src/. Files outside may be overwritten by this tool at any time.
    EOF
  end
  puts <<~EOF
    请选择你的英雄：
    [1] 预览
    [2] 上传
    [3] 只生成而不预览或上传
    [4] 开始编写一篇博客文章
    [9] slzite的原理
    [0] 退出

    Please choose your operation:
    [1] Preview
    [2] Upload
    [3] Only generate without previewing or uploading
    [4] Start writing a blog post
    [9] How slzite works
    [0] Exit
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
      raise UIErrorMessage.new("今天已经写过一篇博客文章了，明天再写吧。")
    end
    File.write(filename, "")
    puts "让我猜猜你最爱用的编辑器。"
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
        puts "你开着的编辑器太多了！选一个你中意的："
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
      　　假如你是李华，你要基于GitHub Pages服务制作静态个人网站，但是觉得Jekyll太难用，又不想直接写HTML和CSS。你在lihua.github.io存储库的src/index.md里写好自我介绍，在src/stylesheet.scss里编写好网站样式，在src/modules/navbar.html里制作好网站导航条，写出网页模板src/modules/main.html：
        <title>李华的个人网站</title>
        <link rel="stylesheet" src="/stylesheet.css">
        <body>
          #include "navbar.html"
          <main>
            #pragma CONTENTS
      　　假如你的英语作文放在src/essay/english/001.md，如果你愿意，可为之使用模板src/modules/essay_english.html，而不是src/modules/main.html。slzblog会处理src目录，自动转换Markdown和SASS文件并套上模板。模板中常见的以/开头的链接也会被替换为相对路径，这样就能直接打开本地网页预览了。如果要直接发布，生成、提交、推送也能自动一气呵成。
      　　按任意键继续……
    EOF
    $stdin.getch
  when "0"
    puts "即将退出。"
    exit
  else
    puts "未知的选项，请重试。"
  end
rescue => exception
  puts "Something happened."
  puts exception.message
  puts exception.backtrace.join("\n") unless exception.is_a?(UIErrorMessage)
  if ARGV[0].nil?
    puts "按任意键退出……"
    $stdin.getch
  end
end

run(ARGV[0] || interface(true))
run(interface(false)) until ARGV[0]
