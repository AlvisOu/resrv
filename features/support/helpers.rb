# features/support/helpers.rb
module WithinHelpers
  def with_scope(locator)
    locator ? within(*selector_for(locator)) { yield } : yield
  end
end

# Custom test helpers
module CustomHelpers
  def current_user_logged_in?
    page.has_link?("Log Out") || page.has_selector?("[data-test='logout']")
  end

  def read_cart_count
    # Tries several common places for a cart count (badge, data-attr, etc.)
    if page.has_selector?("[data-cart-count]", wait: 0.2)
      find("[data-cart-count]", wait: 0.2).text.to_s.strip.to_i
    elsif page.has_selector?("#cart-count", wait: 0.2)
      find("#cart-count", wait: 0.2).text.to_s.strip.to_i
    elsif page.has_selector?(".cart-count", wait: 0.2)
      find(".cart-count", wait: 0.2).text.to_s.strip.to_i
    else
      # Fallback if no badge exists
      0
    end
  end

  def first_cart_line
    # Adjust selectors if your cart rows differ
    first(".cart-line, .cart-row, [data-test='cart-line']")
  end

  def first_cart_qty_input
    first(".cart-line input[type='number'], .cart-row input[type='number'], [data-test='cart-qty']")
  end

  def driver_supports_rack_post?
    page.driver.respond_to?(:post)
  end

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