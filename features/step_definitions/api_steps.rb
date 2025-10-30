require 'uri'
require 'cgi'
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "selectors"))



# --- Post ---
When("I POST to {string} (form) with params:") do |path, table|
  params = table.rows_hash
  page.driver.post(path, params)
end

When("I POST JSON to {string} with:") do |path, body|
  if driver_supports_rack_post?
    page.driver.post(path, body, { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" })
    @last_status = page.status_code if page.respond_to?(:status_code)
    @last_json   = page.body
  else
    js_fetch(method: :POST, path: path, body_str: body, headers: { "Content-Type" => "application/json", "Accept" => "application/json" })
  end
end
When("I PATCH JSON to {string} with:") do |path, body|
  if driver_supports_rack_post?
    page.driver.header("Content-Type", "application/json")
    page.driver.header("Accept", "application/json")
    page.driver.submit(:patch, path, body)
    @last_status = page.status_code if page.respond_to?(:status_code)
    @last_json   = page.body
  else
    js_fetch(method: :PATCH, path: path, body_str: body, headers: { "Content-Type" => "application/json", "Accept" => "application/json" })
  end
end

When("I DELETE JSON {string}") do |path|
  if driver_supports_rack_post?
    page.driver.header("Accept", "application/json")
    page.driver.submit(:delete, path, nil)
    @last_status = page.status_code if page.respond_to?(:status_code)
    @last_json   = page.body
  else
    js_fetch(method: :DELETE, path: path, headers: { "Accept" => "application/json" })
  end
end

Then("the response status should be {int}") do |code|
  status = @last_status || (page.respond_to?(:status_code) ? page.status_code : nil)
  expect(status).to eq(code)
end

When('I POST to {string} (form) with params:') do |path, table|
  params = table.rows_hash

  # Build and submit a real form in the browser so Rails treats this as an HTML request.
  form_html = <<~HTML
    (function(){
      var f = document.createElement('form');
      f.method = 'POST';
      f.action = #{path.inspect};
      // Rails authenticity token, if present on page:
      var meta = document.querySelector('meta[name="csrf-token"]');
      if (meta && meta.content) {
        var t = document.createElement('input');
        t.type = 'hidden';
        t.name = 'authenticity_token';
        t.value = meta.content;
        f.appendChild(t);
      }
      return f;
    })();
  HTML

  form = page.evaluate_script(form_html)
  # Append inputs
  params.each do |k, v|
    page.execute_script(<<~JS)
      (function(){
        var f = document.forms[document.forms.length - 1] || document.querySelector('form[action=#{path.inspect}]');
        var i = document.createElement('input');
        i.type = 'hidden';
        i.name = #{k.inspect};
        i.value = #{v.inspect};
        f.appendChild(i);
      })();
    JS
  end

  # Submit and wait for navigation
  page.execute_script("(document.forms[document.forms.length - 1] || document.querySelector('form[action=#{path.inspect}]')).submit();")
  # Let Capybara detect the new page
  using_wait_time 2 do
    expect(page).to have_current_path(/.+/)
  end
end

Then(/^the JSON response should include "([^"]+)" (true|false)$/) do |key, tf|
  json = JSON.parse(@last_json)
  expect(json[key]).to eq(tf == "true")
end

Then(/^the JSON response should include "([^"]+)" (-?\d+)$/) do |key, intval|
  json = JSON.parse(@last_json)
  expect(json[key]).to eq(intval.to_i)
end


When(/^I POST to "([^"]+)" \(form\) with params:$/) do |path, table|
  params = table.rows_hash

  # Create a form in the browser DOM
  page.execute_script(<<~JS)
    (function(){
      var f = document.createElement('form');
      f.method = 'POST';
      f.action = #{path.inspect};
      var meta = document.querySelector('meta[name="csrf-token"]');
      if (meta && meta.content) {
        var t = document.createElement('input');
        t.type = 'hidden';
        t.name = 'authenticity_token';
        t.value = meta.content;
        f.appendChild(t);
      }
      document.body.appendChild(f);
    })();
  JS

  # Append inputs
  params.each do |k, v|
    page.execute_script(<<~JS)
      (function(){
        var f = document.forms[document.forms.length - 1];
        var i = document.createElement('input');
        i.type = 'hidden';
        i.name = #{k.inspect};
        i.value = #{v.inspect};
        f.appendChild(i);
      })();
    JS
  end

  # Submit and wait for navigation
  page.execute_script("document.forms[document.forms.length - 1].submit();")
  using_wait_time 3 do
    expect(page).to have_current_path(/.+/)
  end
end

Then(/^the JSON response should include "([^"]+)" "([^"]+)"$/) do |key, val|
  json = JSON.parse(@last_json)
  expect(json[key]).to eq(val)
end
