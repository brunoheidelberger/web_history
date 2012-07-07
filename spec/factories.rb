class HtmlDocument
  attr_accessor :body
  attr_accessor :digest
end

FactoryGirl.define do
  factory :html_document do
    body <<-HTML
      <!doctype html>
      <html lang='en'>
        <head>
          <meta charset='utf-8'>
          <title>Document</title>
        </head>
        <body>
          <p>I'm the content.</p>
        </body>
      </html>
    HTML
    digest 'a0441319bc05e6f60c88a3bf74000666da744429'
  end
end

