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
  r.gsub!(/(href|src)=\"\/(.+?)\"/i) { "%s=\"%s\"" % [$1, Pathname.new($2).relative_path_from(Pathname.new(File.dirname(dest_filename)))] }
  r.gsub!(/^\s*#pragma\s+CONTENTS\s*$/, contents)
end

def generate
  if File.read(".git/HEAD").chomp != "ref: refs/heads/master"
    puts "当前不在master分支上，请注意。"
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
  if not true
    puts "生成网站时发生错误。"
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
  system "git diff-index --quiet HEAD || git commit --quiet -m \"slzblog: upload\""
  if not system "git push"
    puts "上传时发生错误。"
  end
end

def interface
  if not Dir.exist?(".git")
    Dir.chdir(__dir__)
    puts "工作目录不在一个git存储库顶端。已切换到slzblog.rb所在目录。"
    if not Dir.exist?(".git")
      raise UIErrorMessage.new("但是这仍不是一个git存储库顶端。")
    end
  end
  option = ARGV[0]
  if not option
    puts <<~EOF
      slzblog是将使用Markdown、SASS、HTML模板技术制作的网站生成为浏览器可以直接查看的网页文件集的工具。注意，本工具与博客并无直接关系。
      警告：网站内容在src目录中。该目录外的内容会随时被本工具覆盖！

      请选择你的英雄：
      [1] 预览
      [2] 上传
      [3] 只生成而不预览或上传
      [4] 开始编写一篇博客文章
      [0] 退出

      Please choose your operation:
      [1] Preview
      [2] Upload
      [3] Only generate without previewing or uploading
      [4] Start writing a blog post
      [0] Exit
    EOF
    option = $stdin.getch
  end
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
  when "0"
    puts "即将退出。"
  else
    puts "未知的选项，即将退出。"
    $stdin.getch
  end
rescue => exception
  puts "发生了一些事情。（Something happened.）"
  puts exception.message
  puts exception.backtrace.join("\n") unless exception.is_a?(UIErrorMessage)
  if ARGV[0].nil?
    puts "按任意键退出……"
    $stdin.getch
  end
end

interface
