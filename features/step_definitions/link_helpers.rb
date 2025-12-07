When('I follow the first {string} link') do |text|
  first(:link, text, exact: false).click
end
