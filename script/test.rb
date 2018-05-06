#!/usr/bin/ruby 
# encoding: utf-8

require 'find'
require 'xcodeproj'
require "net/https"
## ruby编码说明 https://blog.csdn.net/five3/article/details/8966280
#  ruby ./test.rb  --encoding=utf-8  

# root = './src'

# $protoHeaderPath = root + '/proto.h'
# $target 
# projectPath = '../CustomFramework.xcodeproj'
# # puts File.exist?(projectPath)
# project = Xcodeproj::Project.open(projectPath)

# project.targets.each do |t|
# 	# puts t
# 	$target = t;
# end


# #找到要插入的group (参数中true表示如果找不到group，就创建一个group)
# @group = project.main_group.find_subpath(File.join('proto'),true)
# @group.clear
# @group.set_source_tree('SOURCE_ROOT')

def createProtoHeaderFile
	ph = File.new($protoHeaderPath,"w")
	# puts ph 
	configProjectHFile File::expand_path(ph)
end

# traverse directory
def traverseFile(root)
	Find.find(root) do | f |
		# puts f
		if File.file?(f)
			name = File.basename(f)
			if name =~ /.h$/
				# puts name
				bulildHeaderFile name
				configProjectHFile File::expand_path(f)
			elsif name =~ /.m$/
				# puts name
				configProjectMFile File::expand_path(f)
			end
		else
			# puts "is dir"
		end
	end
end

def bulildHeaderFile(fileName)
# originContent = IO.readlines(frameworkHeader)
	File.open($protoHeaderPath, "a+") do |header|
	# originContent.each do |line|
		# header.puts line
		# h ='#import <CustomFramework/' + fileName + '>'
	h = '#import "'+fileName +'"'
		# puts h
	header.puts h
	end
end

def configProjectMFile(filePath)
	# puts 'm file:' + filePath
	ref = @group.new_reference(filePath)
	$target.add_file_references([ref]) 
	# puts ref
end

def configProjectHFile(filePath)
	ref = @group.new_reference(filePath)
	$target.add_file_references([ref],{}) do |buildFile|
		buildFile.settings = { "ATTRIBUTES" => ['Public'] }
	end
end

def downloadFiles(git_host, git_port, token, project_id)
	# http = Net::HTTP.new(git_host, git_port)
	# http.use_ssl = true
	# http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	# http.start {
	# 	headers = {
	# 		'PRIVATE-TOKEN' => token
	# 	}
	# 	path = '/api/v4/projects/%d/repository/commits?per_page=1' % project_id
	# 	http.request_get(path, headers) { |res|
	# 		commits = JSON.parse(res.body)
	# 		if commits then
	# 			last = commits.first
	# 			if last then
	# 				return last['id']
	# 			end
	# 		end
	# 	}
	# }

	open("http://www.ruby-lang.org/en/",
  "User-Agent" => "Ruby/#{RUBY_VERSION}",
  "From" => "foo@bar.invalid",
  "Referer" => "http://www.ruby-lang.org/") {|f|
  # ...
}
end

def unGzip(filePath)
	puts File.exist?(filePath)
	# conn = Zlib::GzipReader.new(StringIO.new(filePath))
	# unzipped = conn.read
	# conn.close

  File.open(filePath) do |f|
  gz = Zlib::GzipReader.new(f)
  # print gz.read
  puts gz.read
  # File.open("./xx","w+") do |nf|
  # 	nf.write(gz.read);
  # end

  gz.close
  end
end

# require 'open-uri'
# File.open('./1.jpg', 'wb') {|f| f.write(open('http://tp1.sinaimg.cn/2264073420/180/40025028927/1') {|f1| f1.read})}

# createProtoHeaderFile
# traverseFile root
# project.save

unGzip "./file.gzip"

