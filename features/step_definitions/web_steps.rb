# --- Navigation ---
Given /^(?:|I )am on (.+)$/ do |page_name|
  visit path_to(page_name)
end
When /^(?:|I )go to (.+)$/ do |page_name|
  visit path_to(page_name)
end

# --- Basic Actions ---
When /^(?:|I )press "([^"]*)"$/ do |button|
  click_button(button)
end
When /^(?:|I )follow "([^"]*)"$/ do |link|
  click_link(link)
end
When /^(?:|I )click "([^"]*)"$/ do |button_or_link|
  click_on(button_or_link)
end
When /^(?:|I )fill in "([^"]*)" with "([^"]*)"$/ do |field, value|
  fill_in(field, with: value)
end
When /^(?:|I )select "([^"]*)" from "([^"]*)"$/ do |value, field|
  select(value, from: field)
end
When /^(?:|I )check "([^"]*)"$/ do |field|
  check(field)
end
When /^(?:|I )uncheck "([^"]*)"$/ do |field|
  uncheck(field)
end
When /^(?:|I )choose "([^"]*)"$/ do |field|
  choose(field)
end
When /^(?:|I )attach the file "([^"]*)" to "([^"]*)"$/ do |path, field|
  attach_file(field, File.expand_path(path))
end

# --- Assertions ---
Then /^(?:|I )should see "([^"]*)"$/ do |text|
  expect(page).to have_content(text)
end
Then /^(?:|I )should see \/([^\/]*)\/$/ do |regexp|
  regexp = Regexp.new(regexp)
  expect(page).to have_xpath('//*', text: regexp)
end
Then /^(?:|I )should not see "([^"]*)"$/ do |text|
  expect(page).to have_no_content(text)
end
Then /^(?:|I )should not see \/([^\/]*)\/$/ do |regexp|
  regexp = Regexp.new(regexp)
  expect(page).to have_no_xpath('//*', text: regexp)
end

Then /^the "([^"]*)" field(?: within (.*))? should contain "([^"]*)"$/ do |field, parent, value|
  with_scope(parent) do
    field_element = find_field(field)
    field_value = (field_element.tag_name == 'textarea') ? field_element.text : field_element.value
    expect(field_value).to match(/#{value}/)
  end
end
Then /^the "([^"]*)" field(?: within (.*))? should not contain "([^"]*)"$/ do |field, parent, value|
  with_scope(parent) do
    field_element = find_field(field)
    field_value = (field_element.tag_name == 'textarea') ? field_element.text : field_element.value
    expect(field_value).not_to match(/#{value}/)
  end
end
Then /^the "([^"]*)" field should have the error "([^"]*)"$/ do |field, error_message|
  element = find_field(field)
  classes = element.find(:xpath, '..')[:class].split(' ')

  form_for_input = element.find(:xpath, 'ancestor::form[1]')
  using_formtastic = form_for_input[:class].include?('formtastic')
  error_class = using_formtastic ? 'error' : 'field_with_errors'

  expect(classes).to include(error_class)

  if using_formtastic
    error_paragraph = element.find(:xpath, '../*[@class="inline-errors"][1]')
    expect(error_paragraph).to have_content(error_message)
  else
    expect(page).to have_content("#{field.titlecase} #{error_message}")
  end
end
Then /^the "([^"]*)" field should have no error$/ do |field|
  element = find_field(field)
  classes = element.find(:xpath, '..')[:class].split(' ')
  expect(classes).not_to include('field_with_errors')
  expect(classes).not_to include('error')
end

Then /^the "([^"]*)" checkbox(?: within (.*))? should be checked$/ do |label, parent|
  with_scope(parent) do
    field_checked = find_field(label)['checked']
    expect(field_checked).to be(true)
  end
end
Then /^the "([^"]*)" checkbox(?: within (.*))? should not be checked$/ do |label, parent|
  with_scope(parent) do
    field_checked = find_field(label)['checked']
    expect(field_checked).to be(false)
  end
end
 
Then /^(?:|I )should be on (.+)$/ do |page_name|
  current_path = URI.parse(current_url).path
  expect(current_path).to eq(path_to(page_name))
end

Then /^(?:|I )should have the following query string:$/ do |expected_pairs|
  query = URI.parse(current_url).query
  actual_params = query ? CGI.parse(query) : {}
  expected_params = {}
  expected_pairs.rows_hash.each_pair{|k,v| expected_params[k] = v.split(',')} 
  
  expect(actual_params).to eq(expected_params)
end

Then /^show me the page$/ do
  save_and_open_page
end