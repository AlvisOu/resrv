module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

    when /^the sign up page$/ then signup_path

    when /^the home\s?page$/ then root_path

    when /^my owned\/bookmarked workspaces$/ then root_path

    when /^the profile page$/ then profile_path

    when /^"\/workspaces\?query=(.+)"$/ then "/workspaces?query=#{$1}"

    when /^the edit page for workspace "([^"]+)"$/ then edit_workspace_path(Workspace.find_by!(name: $1))

    when /^cart$/ then cart_path

    when /^My Reservations$/ then reservations_path

    when /^the "([^"]*)" workspace page$/
      workspace_path(Workspace.find_by!(name: $1))

    when /^my owned\/bookmarked workspaces$/
      workspaces_path

    when /^the "([^"]*)" management page$/
      manage_workspace_path(Workspace.find_by!(name: $1))

    when /^my "(.+)" workspace$/
      workspace = Workspace.find_by(name: $1)
      raise "Workspace '#{$1}' not found" unless workspace
      workspace_path(workspace)

    when /my notifications page/
      notifications_path

    else
      begin
        page_name =~ /^the (.*) page$/
        path_components = ::Regexp.last_match(1).split(/\s+/)
        send(path_components.push('path').join('_').to_sym)
      rescue NoMethodError, ArgumentError
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" \
              "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end
end

World(NavigationHelpers)
