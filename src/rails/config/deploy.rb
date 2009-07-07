set :application, "sandbox.twitch.highorderbit.com"

#
# Server configuration
#
set :user, "highorderbit"

role :app, "#{user}@#{application}"
role :web, "#{user}@#{application}"
role :db, "#{user}@#{application}"

#
# SCM Configuration
#

default_run_options[:pty] = true  # required to get the password prompt from git
set :repository, "git@github.com:highorderbit/twitch.git"
set :scm, "git"
set :scm_username, "jad"
set :scm_passphrase, proc{Capistrano::CLI.password_prompt('git password:')}
set :branch, "master"

ssh_options[:forward_agent] = true

# If you have previously been relying upon the code to start, stop 
# and restart your mongrel application, or if you rely on the database
# migration code, please uncomment the lines you require below

# If you are deploying a rails app you probably need these:

#load 'ext/rails-database-migrations.rb'
#load 'ext/rails-shared-directories.rb'

# There are also new utility libaries shipped with the core these 
# include the following, please see individual files for more
# documentation, or run `cap -vT` with the following lines commented
# out to see what they make available.

#load 'ext/spinner.rb'              # Designed for use with script/spin
#load 'ext/passenger-mod-rails.rb'  # Restart task for use with mod_rails
#load 'ext/web-disable-enable.rb'   # Gives you web:disable and web:enable

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/home/#{user}/#{application}"

# The sandbox runs on a shared host; configure restarts appropriately
set :use_sudo, false
set :run_method, :run

namespace(:deploy) do
  desc "Restart Passenger on a shared host"
  task :restart do
    FileUtils.touch("#{deploy_to}/current/src/rails/tmp/restart.txt")
  end
end
