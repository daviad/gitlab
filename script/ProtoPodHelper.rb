#!/usr/bin/ruby


require "net/https"
require 'json'

$target_name = ''

def get_last_commit_id(git_host, git_port, token, project_id)
	http = Net::HTTP.new(git_host, git_port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	http.start {
		headers = {
			'PRIVATE-TOKEN' => token
		}
		path = '/api/v4/projects/%d/repository/commits?per_page=1' % project_id
		http.request_get(path, headers) { |res|
			commits = JSON.parse(res.body)
			if commits then
				last = commits.first
				if last then
					return last['id']
				end
			end
		}
	}
	return nil
end

def podspec_prepare(item)
	commit_id = get_last_commit_id(item[:git_host], item[:git_port], item[:token], item[:project_id])
	raise "Failed to reach gitlab server or can not parse response data" if !commit_id

	spec_path = item[:spec_path]
	if !File.exists?(spec_path) then
		raise spec_path + " not found"
	end

	f = File.open(spec_path, 'r')
	spec_json = JSON.parse(f.read())

	if !spec_json then
		raise 'spec parse error'
	end

	if spec_json['source']['commit'] != commit_id then
		spec_json['source']['commit'] = commit_id
		File.open(spec_path, 'w') do |f|
			print "Update commit id to ", commit_id, "\n"
			f.write(JSON.pretty_generate(spec_json))
		end
	end
end


def proto_path_tree(root)
	print "root = ", root, "\n"
    folders = Queue.new
    list = []
    rpath = ""
    folders.push(rpath)
    while !folders.empty?()
        parent = folders.pop()
        Dir.foreach(root + parent) { |p|
            if p == '.' || p == '..'
                next
            end
            rpath = parent.empty?() ? p : parent + "/" + p
            if File::directory?(root + rpath)
                folders.push(rpath)
            else
                list.push(rpath)
            end
        }
    end
    return list
end

=begin
物理目录
1.objc_out
2.proto_path
3.proto_file_paths

虚拟目录
source_file_paths

hash表
md5(proto_file_path) => md5(file_content_of(proto_file_path))

=end

def build_head_file_banner(name)
	return "//
//  %s.h
//
//  Created by jqoo on 2017/10/16.
//  Copyright © 2017年 jqoo. All rights reserved.
//

" % name
end

# 生成单个分组的头文件
def build_group_head_file(folder_path, name)
	head_file_names = []
	group_header_name = name + '.h'
	Dir.foreach(folder_path) do |file|
		if file.end_with?('.h') && file != group_header_name
			head_file_names.push(file)
		end
	end
	head_file_names = head_file_names.sort()

	path = folder_path + group_header_name
    File.open(path, 'w') do |f|
        f.write(build_head_file_banner(name))
        head_file_names.each do |file|
            f.write("#import \"" + file + "\"\n")
        end
    end
    return path
end

def find_target(project, target_name)
    project.targets.each do |target|
    	print "target is ", target
        if target.name == target_name then
            return target
        end
    end
    return nil
end

# 生成导出头文件
def build_export_head_file(folder_path, name)
	head_file_names = []
	Dir.foreach(folder_path) do |file|
		head_file = folder_path + (file + '/' + file + '.h')
		if File.exist?(head_file)
			head_file_names.push(file + '.h')
		end
	end
	head_file_names = head_file_names.sort()
	path = folder_path + (name + '.h')
    File.open(path, 'w') do |f|
        f.write(build_head_file_banner(name))
        head_file_names.each do |file|
            f.write("#import \"" + file + "\"\n")
        end
    end
    return path
end

# 将proto编译生成的文件添加到工程
def add_source_files(parent_group, source_file_group_name, source_file_folder)
	source_file_group = parent_group.new_group(source_file_group_name, source_file_folder)
	file_refs = []
	target = find_target(parent_group.project, $target_name)

	head_file_names = []
	Dir.foreach(source_file_folder) do |file|
		if file.end_with?('.h') || file.end_with?('.m')
			fullpath = source_file_folder + file
			file_ref = source_file_group.new_file(fullpath)
			file_refs.push(file_ref)

			if file.end_with?('.m')
				target.add_file_references([file_ref], '-fno-objc-arc')
			else
				head_file_names.push(file)
				target.add_file_references([file_ref]) do |build_file|
		          build_file.settings = { 'ATTRIBUTES' => ['Public'] }
		        end
			end
		end
	end
end

# 将export header添加到工程
def add_export_head_file(parent_group, head_file_path)
	file_ref = parent_group.new_file(head_file_path)
	target = find_target(parent_group.project, $target_name)
	target.add_file_references([file_ref]) do |build_file|
        build_file.settings = { 'ATTRIBUTES' => ['Public'] }
    end
end

# 添加分组、编译proto、添加虚拟目录、更新摘要json
def build_protos(protc, proto_group, pbobjc_group, proto_rpath)
	proto_path = proto_group.real_path + proto_rpath
	# 命名规则：将路径形式转换为点分形式，如src/main/proto转为src.main.proto，是为了方便，不然层次太多
	out_name = proto_rpath.gsub(/\//, '.')
	objc_out = pbobjc_group.real_path + out_name

	if !Dir.exist?(objc_out)
		Dir.mkdir(objc_out)
	end

	begin # 编译proto
	    proto_list = []
		Dir.foreach(proto_path) do |file|
		    if file.end_with?('.proto')
		    	proto_list.push(file)
		    end
		end
		cmd_comps = [protc]
		cmd_comps.push('--proto_path=' + proto_path.to_s)
	    cmd_comps.push('--objc_out=' + objc_out.to_s)
	    cmd_comps << proto_list

	    cmd = cmd_comps.join(' ')
	    system cmd
	    build_group_head_file(objc_out, out_name)
	end

	add_source_files(pbobjc_group, out_name, objc_out)

end

def proto_project_load(item)
	installer = item[:installer]
	$target_name = item[:proto_target]
	proto_rpaths = item[:proto_rpaths]

	project = installer.pods_project

	proto_group = project.pods[$target_name]
	print 'proto_group : ', proto_group.real_path.to_s, "\n"

	pbobjc_path = proto_group.parent.real_path + 'pbobjc'
	if !Dir.exist?(pbobjc_path)
		Dir.mkdir(pbobjc_path)
	end
	pbobjc_group = project.pods.new_group('pbobjc', pbobjc_path)

	protoc_bin_path = item[:protoc]
	proto_rpaths.each do |rpath|
		build_protos(protoc_bin_path, proto_group, pbobjc_group, rpath)
	end
	export_file = build_export_head_file(pbobjc_path, $target_name)
	add_export_head_file(pbobjc_group, export_file)

	find_target(project, $target_name).build_configurations.each do |config|
      	config.build_settings.merge!('HEADER_SEARCH_PATHS' => item[:protobuf_include])
	end
end
