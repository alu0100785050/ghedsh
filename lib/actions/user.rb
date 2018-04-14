require 'require_all'
require_rel '.'
require 'common'
require_relative '../helpers'
require 'ostruct'

class User
  # Defined as method class in order to call it within context.rb
  def self.shell_prompt(config)
    if config['Repo'].nil?
      Rainbow("#{config['User']}> ").aqua
    else
      Rainbow("#{config['User']}> ").aqua + Rainbow("#{config['Repo']}> ").color(236, 151, 21)
    end
  end

  def build_cd_syntax(type, name)
    syntax_map = { 'repo' => "User.new.cd('repo', #{name}, client, env)",
                   'org' => "User.new.cd('org', #{name}, client, env)" }
    unless syntax_map.key?(type)
      raise Rainbow("cd #{type} currently not supported.").color('#cc0000')
    end
    syntax_map[type]
  end

  def open_info(config, _params = nil, _client = nil)
    if config['Repo'].nil?
      open_url(config['user_url'].to_s)
    else
      open_url(config['repo_url'].to_s)
    end
  end

  def cd_org(name, client, enviroment)
    if name.class == Regexp
      pattern = Regexp.new(name.source)
      user_orgs = []
      user_orgs_url = {}
      spinner = custom_spinner("Matching #{client.login} organizations :spinner ...")
      spinner.auto_spin
      client.organizations.each do |org|
        if pattern.match((org[:login]).to_s)
          user_orgs << org[:login]
          user_orgs_url[org[:login].to_s] = 'https://github.com/' << org[:login].to_s
        end
      end
      spinner.stop(Rainbow('done!').color(4, 255, 0))
      if user_orgs.empty?
        puts Rainbow("No organization match with #{name.source}").color('#9f6000')
        puts
        return nil
      else
        prompt = TTY::Prompt.new
        answer = prompt.select('Select desired organization', user_orgs)
        enviroment.config['Org'] = answer
        enviroment.config['org_url'] = user_orgs_url[answer]
        enviroment.deep = Organization
      end
    else
      if client.organization_member?(name.to_s, client.login.to_s)
        enviroment.config['Org'] = name
        enviroment.config['org_url'] = 'https://github.com/' << name.to_s
        enviroment.deep = Organization
      else
        puts Rainbow("You are not currently #{name} member or #{name} is not an Organization.").color('#9f6000')
        puts
        return nil
      end
    end
    enviroment
  end

  def cd_repo(name, client, enviroment)
    if name.class == Regexp
      pattern = Regexp.new(name.source)
      user_repos = []
      user_repos_url = {}
      spinner = custom_spinner("Matching #{client.login} repositories :spinner ...")
      spinner.auto_spin
      client.repositories.each do |repo|
        if pattern.match(repo[:name].to_s)
          user_repos << repo[:name]
          user_repos_url[repo[:name].to_s] = repo[:html_url]
        end
      end
      spinner.stop(Rainbow('done!').color(4, 255, 0))
      if user_repos.empty?
        puts Rainbow("No repository match with \/#{name.source}\/").color('#9f6000')
        return nil
      else
        prompt = TTY::Prompt.new
        answer = prompt.select('Select desired repository', user_repos)
        enviroment.config['Repo'] = answer
        enviroment.config['repo_url'] = user_repos_url[answer]
        enviroment.deep = User
      end
    else
      if client.repository?("#{client.login}/#{name}")
        res = {}
        # client.repository returns array of arrays (in hash format)[ [key1, value1], [key2, value2] ]
        # thats why first we convert the api response to hash
        client.repository("#{client.login}/#{name}").each do |key, value|
          res[key] = value
        end
        enviroment.config['Repo'] = name
        enviroment.config['repo_url'] = res[:html_url]
        enviroment.deep = User
      else
        puts Rainbow("Maybe #{name} is not a repository or currently does not exist.").color('#9f6000')
        return nil
      end
    end
    enviroment
  end

  def cd(type, name, client, enviroment)
    cd_scopes = { 'org' => method(:cd_org), 'repo' => method(:cd_repo) }
    cd_scopes[type].call(name, client, enviroment)
  end

  def show_repos(client, _config, params)
    spinner = custom_spinner("Fetching #{client.login} repositories :spinner ...")
    spinner.auto_spin
    user_repos = []
    client.repositories.each do |repo|
      user_repos << repo[:name]
    end
    spinner.stop(Rainbow('done!').color(4, 255, 0))
    if params.nil?
      user_repos.each do |repo_name|
        puts repo_name
      end
    else
      pattern = build_regexp_from_string(params)
      occurrences = show_matching_items(user_repos, pattern)
      puts Rainbow("No repository matched \/#{pattern.source}\/").color('#00529B') if occurrences.zero?
    end
  end

  def show_organizations(client, params)
    spinner = custom_spinner("Fetching #{client.login} organizations :spinner ...")
    spinner.auto_spin
    user_orgs = []
    client.list_organizations.each do |org|
      user_orgs << org[:login]
    end
    spinner.stop(Rainbow('done!').color(4, 255, 0))
    if params.empty?
      user_orgs.each do |org_name|
        puts org_name
      end
    else
      pattern = build_regexp_from_string(params[0])
      occurrences = show_matching_items(user_orgs, pattern)
      puts Rainbow("No organization matched \/#{pattern.source}\/").color('#00529B') if occurrences.zero?
    end
  end

  def create_repo(client, repo_name, options)
    client.create_repository(repo_name, options)
    puts Rainbow('Repository created correctly!').color(79, 138, 16)
  rescue StandardError => exception
    puts Rainbow(exception.message.to_s).color('#cc0000')
    puts
  end

  def remove_repo(client, repo_name)
    client.delete_repository("#{client.login}/#{repo_name}")
    puts Rainbow('Repository deleted.').color('#00529B')
  rescue StandardError => exception
    puts
    puts Rainbow(exception.message.to_s).color('#cc0000')
  end

  def clone_repository(client, repo_name)
    ssh_url = []
    if repo_name.include?('/')
      pattern = build_regexp_from_string(repo_name)
      client.repositories.each do |repo|
        ssh_url << repo[:clone_url] if pattern.match(repo[:name])
      end
      puts Rainbow("No repository matched \/#{pattern.source}\/").color('#00529B') if ssh_url.empty?
    else
      repo = client.repository("#{client.login}/#{repo_name}")
      ssh_url << repo[:ssh_url]
    end
    unless ssh_url.empty?
      perform_git_clone(ssh_url)
      puts Rainbow("Cloned files are on directory #{Dir.home}/ghedsh_cloned").color('#00529B')
      puts
    end
  rescue StandardError => exception
    puts Rainbow(exception.message.to_s).color('#cc0000')
    puts
  end

  def show_commits(enviroment, params)
    options = {}
    if !enviroment.config['Repo'].nil?
      repo = enviroment.config['Repo']
      options[:sha] = if params.empty?
                        'master'
                      else
                        params[0]
                      end
    else
      repo = params[0]
      options[:sha] = if params[1].nil?
                        'master'
                      else
                        params[1]
                      end
    end
    begin
      enviroment.client.commits("#{enviroment.client.login}/#{repo}", options).each do |i|
        puts "\tSHA: #{i[:sha]}"
        puts "\t\t Commit date: #{i[:commit][:author][:date]}"
        puts "\t\t Commit author: #{i[:commit][:author][:name]}"
        puts "\t\t\t Commit message: #{i[:commit][:message]}"
      end
    rescue StandardError => exception
      puts exception
      puts Rainbow("If you are not currently on a repo, USAGE TIP: `commits <repo_name> [branch_name]` (default: 'master')").color('#00529B')
    end
  end
end
