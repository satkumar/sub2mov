worker_processes 4
listen "/tmp/sub2mov.socket", :backlog => 64
preload_app true
timeout 30
pid "/tmp/unicorn.sub2mov.pid"

working_directory "/home/kage/cs290N/app/sub2mov"
shared_path = "/home/kage/cs290N/app/sub2mov"
stderr_path "#{shared_path}/log/unicorn.stderr.log"
stdout_path "#{shared_path}/log/unicorn.stdout.log"

before_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end

  old_pid = "/tmp/unicorn.sub2mov.pid.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
  end
end
