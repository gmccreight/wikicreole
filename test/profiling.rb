#!/usr/bin/env ruby

require 'wiki_creole'
require 'ruby-prof'

WikiCreole.init

result = RubyProf.profile do
  10.times do
    %w(amp block escape inline specialchars jsp_wiki).each do |name|
      markup = File.read("./test/test_#{name}.markup")
      parsed = WikiCreole.parse(markup, :top)
    end
  end
end

printer = RubyProf::GraphHtmlPrinter.new(result)
File.open("profiling.html", "w") do |file|
  printer.print(file)
end

