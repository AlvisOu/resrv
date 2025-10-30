# features/support/helpers.rb
module WithinHelpers
  def with_scope(locator)
    locator ? within(*selector_for(locator)) { yield } : yield
  end
end

# Custom Helpers
module CartHelpers
  def read_cart_count
    if page.has_selector?("[data-cart-count]", wait: 0.2)
      find("[data-cart-count]", wait: 0.2).text.to_s.strip.to_i
    elsif page.has_selector?("#cart-count", wait: 0.2)
      find("#cart-count", wait: 0.2).text.to_s.strip.to_i
    elsif page.has_selector?(".cart-count", wait: 0.2)
      find(".cart-count", wait: 0.2).text.to_s.strip.to_i
    else
      0
    end
  end

  def add_item_to_cart(selections)
    body = { selections: selections }.to_json
    path = "/cart_items.json"
    headers = { "Content-Type" => "application/json", "Accept" => "application/json" }
    if page.driver.respond_to?(:post)
      page.driver.post(path, body, headers)
      @last_status = page.status_code if page.respond_to?(:status_code)
      @last_json   = page.body
    else
      js_fetch(method: :POST, path: path, body_str: body, headers: headers)
    end
  end
end

module APIHelpers
  def js_fetch(method:, path:, body_str: nil, headers: {})
    # Use browser fetch to make the request and return {status, body}
    headers_js = headers.to_json
    body_js    = body_str.nil? ? 'undefined' : body_str.to_s.inspect

    script = <<~JS
      const done = arguments[0];
      fetch(#{path.inspect}, {
        method: #{method.to_s.inspect},
        headers: #{headers_js},
        body: #{body_js}
      }).then(async (r) => {
        const text = await r.text();
        done(JSON.stringify({status: r.status, body: text}));
      }).catch(e => done(JSON.stringify({status: 0, body: String(e)})));
    JS

    raw = page.evaluate_async_script(script)
    JSON.parse(raw).tap do |res|
      @last_status = res["status"]
      @last_json   = res["body"]
    end
  end
end