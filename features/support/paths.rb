module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

    when /^the home\s?page$/ then root_path

    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(User.find_by_login($1))
    when /^the edit page for "(.*)"$/
      movie = Movie.find_by!(title: $1)
      edit_movie_path(movie)
      
    when /^the details page for "(.*)"$/
      movie = Movie.find_by!(title: $1)
      movie_path(movie)

    when /^the Similar Movies page for "(.*)"$/
      movie = Movie.find_by!(title: $1)
      similar_movie_path(movie)

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
