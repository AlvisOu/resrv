# --- Actions ---
When(/^I POST to "([^"]+)" \(form\) with params:$/) do |path, table|
  params = table.rows_hash
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
  page.execute_script("document.forms[document.forms.length - 1].submit();")
  using_wait_time 3 do
    expect(page).to have_current_path(/.+/)
  end
end
When("I PATCH JSON to {string} with:") do |path, body|
  if page.driver.respond_to?(:post)
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
  if page.driver.respond_to?(:post)
    page.driver.header("Accept", "application/json")
    page.driver.submit(:delete, path, nil)
    @last_status = page.status_code if page.respond_to?(:status_code)
    @last_json   = page.body
  else
    js_fetch(method: :DELETE, path: path, headers: { "Accept" => "application/json" })
  end
end

# --- Sees ---
Then("the response status should be {int}") do |code|
  status = @last_status || (page.respond_to?(:status_code) ? page.status_code : nil)
  expect(status).to eq(code)
end
Then(/^the JSON response should include "([^"]+)" (true|false)$/) do |key, tf|
  json = JSON.parse(@last_json)
  expect(json[key]).to eq(tf == "true")
end
Then(/^the JSON response should include "([^"]+)" (-?\d+)$/) do |key, intval|
  json = JSON.parse(@last_json)
  expect(json[key]).to eq(intval.to_i)
end
Then(/^the JSON response should include "([^"]+)" "([^"]+)"$/) do |key, val|
  json = JSON.parse(@last_json)
  expect(json[key]).to eq(val)
end

Then("the response content type should be {string}") do |content_type|
  expect(page.response_headers['Content-Type']).to include(content_type)
end
