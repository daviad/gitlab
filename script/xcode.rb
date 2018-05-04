require 'xcodeproj'
project_path = '/Users/dxw/Desktop/github/HainanTelcom/HaiNanTelecom/HaiNanTelecom.xcodeproj'    # 工程的全路径
project = Xcodeproj::Project.open(project_path)

 # 1、显示所有的target
project.targets.each do |target|
  puts target.name
end

# 2、显示第一个target的所有Compile Sources
target = project.targets.first
files = target.source_build_phase.files.to_a.map do |pbx_build_file|
    pbx_build_file.file_ref.real_path.to_s
end.select do |path|
  path.end_with?(".m", ".mm", ".swift")
end.select do |path|
  puts path
end

# # 3、创建一个target 并添加文件
# app_target = project.new_target(:application, 'demo', :ios, '6.0')
# header_ref = project.main_group.new_file('./Class.h')
# implm_ref = project.main_group.new_file('./Class.m')
# app_target.add_file_references([implm_ref])
# project.save()