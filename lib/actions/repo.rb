require 'readline'
require 'octokit'
require 'json'
require 'require_all'
require_rel '.'

class Repositories

  #scope = 1 -> organization repos
  #scope = 2 -> user repos
  #scope = 3 -> team repos

  def show_commits(client,config,scope)
    print "\n"
    case
      when scope==1
        mem=client.commits(config["Org"]+"/"+config["Repo"],"master")
      when scope==2
        mem=client.commits(config["User"]+"/"+config["Repo"],"master")
    end
    mem.each do |i|
      print i[:sha],"\n",i[:commit][:author][:name],"\n",i[:commit][:author][:date],"\n",i[:commit][:message],"\n\n"
    end
  end

  def show_repos(client,config,scope)
    print "\n"
    reposlist=[]
    case
      when scope==1
        repo=client.repositories
      when scope==2
        repo=client.organization_repositories(config["Org"])
      when scope==3
        repo=client.team_repositories(config["TeamID"])
    end
    repo.each do |i|
      puts i.name
      reposlist.push(i.name)
      #self.add_history(i.name)
    end
    print "\n"
    return reposlist
  end

  def show_forks(client,config,scope)
    print "\n"
    forklist=[]
    case
      when scope==1
        mem=client.forks(config["Org"]+"/"+config["Repo"])
    end
    mem.each do |i|
      puts i[:owner][:login]
      forklist.push(i[:owner][:login])
    end
    print "\n"
    return forklist
  end

  def show_collaborators(client,config,scope)
    print "\n"
    collalist=[]
    case
    when scope==1
      mem=client.collaborators(config["Org"]+"/"+config["Repo"])
    end
    mem.each do |i|
      puts i[:author][:login]
      collalist.push(i[:author][:login])
    end
    print "\n"
    return collalist
  end


  
end