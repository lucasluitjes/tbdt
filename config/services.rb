ServiceManager.define_service 'directory_server' do |s|
  s.host       = 'localhost'
  s.port       = 8070

  s.start_cmd  = "ruby directory_server.rb -p #{s.port}"

  s.loaded_cue = /Listening on/

  s.color      = 37
  s.cwd        = Dir.pwd

  s.timeout    = 120
end

3.times do |i|
  ServiceManager.define_service "node#{i + 1}" do |s|
    s.host       = 'localhost'
    s.port       = 8081 + i

    s.start_cmd  = "ruby main.rb -p #{s.port}"

    s.loaded_cue = /Listening on/

    s.color      = i + 33
    s.cwd        = Dir.pwd

    s.timeout    = 120
  end
end
