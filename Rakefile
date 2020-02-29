VERSION = File.read('CHANGELOG.md')[/v([\d\.]+) /, 1]

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

