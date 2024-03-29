require 'rubygems'
require 'rake'
require 'rake/clean'
require 'find'

def project_file(root_dir='.')
  Find.find(root_dir) do |f|
    if f =~ /\.xcodeproj$/
      return f
    end
  end
  nil
end

def xcodebuild
  "xcodebuild -project #{project_file}"
end

task :default => [:build]

desc 'List available SDKs'
task :show_sdks do |t|
  puts %x{ #{xcodebuild} -showsdks }
end

desc 'Clean everything'
task :clean do |t|
  puts %x{ #{xcodebuild} -alltargets clean }
end

desc 'Build the default target using the default configuration'
task :build do |t|
  puts %x{
    #{xcodebuild} |
    grep -v "note: This view overlaps one of its siblings."
  }
end

desc 'List available targets'
task :list_targets do |t|
  puts %x{ #{xcodebuild} -list }
end

desc 'Pull latest from Git'
task :pull do |t|
  branch = ENV.include?('branch') ? ENV['branch'] : 'master'
  puts %x{ git pull origin #{branch} }
  Rake::Task['build_tags'].invoke
end

desc 'Push latest to Git'
task :push do |t|
  branch = ENV.include?('branch') ? ENV['branch'] : 'master'
  puts %x{ git push origin #{branch} }
end

task :build_tags do |t|
  src_dir =
    File.expand_path(File.dirname(__FILE__) + "/src/Classes")
  tags_file = "#{src_dir}/tags"

  print "Rebuilding tags in '#{tags_file}'..."
  output =
    %x{
        etags --language=objc --output=tags #{src_dir}/**/*.h #{src_dir}/**/*.m
      }
  if (output.chomp.length > 0)
    puts ""      # print a newline
    puts output  # only produces output if there's an error
  else
    puts "done."
  end
end
