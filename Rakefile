VERSION = File.read('CHANGELOG.md')[/v([\d\.]+) /, 1]

task :build do
  sh "bundle exec erb -r ./demo/erb_helper.rb views/index.erb > demo/index.html"
  sh "bundle exec opal -c ovto/app.rb -g ovto -I ./ovto/ > demo/demo.js"
end

desc "git ci, git tag and git push"
task :release do
  sh "git diff HEAD"
  v = "v#{VERSION}"
  puts "release as #{v}? [y/N]"
  break unless $stdin.gets.chomp == "y"

  sh "git ci -am '#{v}'"
  sh "git tag '#{v}'"
  sh "git push origin master --tags"
end

