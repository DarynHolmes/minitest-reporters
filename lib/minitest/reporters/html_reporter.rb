require 'builder'
require 'fileutils'
require 'erb'
module Minitest
  module Reporters
    class HtmlReporter <  BaseReporter
      def initialize(reports_dir = "test/html_reports", empty = true)
        super({})
        @reports_path = File.absolute_path(reports_dir)

        if empty
          puts "Emptying #{@reports_path}"
          FileUtils.remove_dir(@reports_path) if File.exists?(@reports_path)
          FileUtils.mkdir_p(@reports_path)
        end
      end

      def report
        super

        puts "Writing HTML reports to #{@reports_path}"
        status_line = "Finished tests in %.6fs, %.4f tests/s, %.4f assertions/s." %
            [total_time, count / total_time, assertions / total_time]
        puts "html: " + status_line


        erb_file =  'lib/minitest/templates/index.html.erb'
        html_file = @reports_path + "/index.html"
        erb_str = File.read(erb_file)
        renderer = ERB.new(erb_str)
        result = renderer.result(binding)

        File.open(html_file, 'w') do |f|
          f.write(result)
        end

        # suites = tests.group_by(&:class)
        # suites.each do |suite, tests|
        #   suite_result = analyze_suite(tests)
        #
        #   xml = Builder::XmlMarkup.new(:indent => 2)
        #   xml.instruct!
        #   xml.testsuite(:name => suite, :skipped => suite_result[:skip_count], :failures => suite_result[:fail_count],
        #                 :errors => suite_result[:error_count], :tests => suite_result[:test_count],
        #                 :assertions => suite_result[:assertion_count], :time => suite_result[:time]) do
        #     tests.each do |test|
        #       xml.testcase(:name => test.name, :classname => suite, :assertions => test.assertions,
        #                    :time => test.time) do
        #         xml << xml_message_for(test) unless test.passed?
        #       end
        #     end
        #   end
        #   File.open(filename_for(suite), "w") { |file| file << xml.target! }
        # end
      end



      private


    end
  end
end
