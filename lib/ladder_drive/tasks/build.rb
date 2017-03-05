# The MIT License (MIT)
#
# Copyright (c) 2016 ITO SOFT DESIGN Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

dir = File.expand_path(File.join(File.dirname(__FILE__), "../../../lib"))
$:.unshift dir unless $:.include? dir

require 'rake/loaders/makefile'
require 'fileutils'
require "ladder_drive"

directory "build"

desc "Assemble codes"
rule %r{^build/.+\.lst} => ['%{^build,asm}X.esc'] do |t|
  Rake::Task["build"].invoke
  begin
    $stderr = File.open('hb.log', 'w')
    $stdout = $stderr
  ensure
    $stdout = STDOUT
    $stderr = STDERR
  end
  #dir = "./asm"
  stream = StringIO.new
  #filename = "asm/#{t.source}"
  puts "asm #{t.source}"
  asm = LadderDrive::Asm.new File.read(t.source)
  #dst = File.join("build", t.name)
  File.write(t.name, asm.dump_line)
end

desc "Make hex codes"
rule %r{^build/.+\.hex} => ['%{^build,asm}X.esc'] do |t|
  Rake::Task["build"].invoke
  begin
    $stderr = File.open('hb.log', 'w')
    $stdout = $stderr
  ensure
    $stdout = STDOUT
    $stderr = STDERR
  end
  stream = StringIO.new
  puts "hex #{t.source}"
  asm = LadderDrive::Asm.new File.read(t.source)
  hex = LadderDrive::IntelHex.new asm.codes
  File.write(t.name, hex.dump)
end

desc "Clean all generated files."
task :clean do
  FileUtils.rm_r "build"
end

@config = LadderDrive::LadderDriveConfig.default

desc "Install program to PLCs."
task :upload => @config.output do
  t = @config.target ENV['target']
  t.run
  u = t.uploader
  u.source = @config.output
  puts "uploading #{u.source} ..."
  u.upload
  puts "done uploading"
end

desc "Launch emulator."
task :emulator do
  t = @config.target :emulator
  t.run
  puts "launch emulator"
  LadderDrive::Console.instance.run
end

task :console => :upload do
  c = LadderDrive::Console.instance
  c.target = @config.target ENV['target']
  c.run
end

task :default => :console