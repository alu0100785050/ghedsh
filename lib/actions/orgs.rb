require 'readline'
require 'octokit'
require 'json'
require 'require_all'
require_rel '.'

class Organizations

  attr_accessor :orgslist

  #all asignements stuff
  def show_organization_members_bs(client,config)
    @orgslist=[]
    print "\n"
    mem=client.organization_members(config["Org"])
    mem.each do |i|
      m=eval(i.inspect)
      @orgslist.push(m[:login])
      puts m[:login]
    end
    return @orgslist
  end

end
