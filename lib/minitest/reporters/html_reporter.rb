require 'builder'
require 'fileutils'
require 'erb'
require 'awesome_print'
module Minitest
  module Reporters
    class HtmlReporter < BaseReporter
      def initialize(reports_dir = "test/html_reports", empty = true)
        @report_title = 'Fulcrum Specs'
        super({})
        @reports_path = File.absolute_path(reports_dir)

        if empty
          puts "Emptying #{@reports_path}"
          FileUtils.remove_dir(@reports_path) if File.exists?(@reports_path)
          FileUtils.mkdir_p(@reports_path)
        end
      end

      def passes
        count - failures - errors - skips
      end

      def report
        super

        puts "Writing HTML reports to #{@reports_path}"
        erb_file = 'lib/minitest/templates/index.html.erb'
        html_file = @reports_path + "/index.html"
        erb_str = File.read(erb_file)
        renderer = ERB.new(erb_str)

        tests_by_groups = tests.group_by(&:class) # taken from the JUnit reporter
        suites = []
        tests_by_groups.each do |suite_name, tests|
          suite_result = analyze_suite(tests)
          suite_result[:name] = suite_name
          suite_result[:tests] = []
          tests.each do |test|
            test_map = {}
            test_map[:name] = friendly_name(test)
            test_map[:classname] = suite_name
            test_map[:assertion_count] = test.assertions
            test_map[:time] = test.time
            test_map[:result] = result(test)
            test_map[:message] = test.failure.message unless test.passed?
            test_map[:location] = location(test.failure) unless test.passed?

            suite_result[:tests] << test_map
          end
          suites << suite_result
        end

        result = renderer.result(binding)

        File.open(html_file, 'w') do |f|
          f.write(result)
        end
      end

      private

      def friendly_name(test)
        groups = test.name.scan(/(test_\d+_)(.*)/i)
        "it #{groups[0][1]}"
      end

      # taken from the JUnit reporter
      def analyze_suite(tests)
        result = Hash.new(0)
        tests.each do |test|
          result[:"#{result(test)}_count"] += 1
          result[:assertion_count] += test.assertions
          result[:test_count] += 1
          result[:time] += test.time
        end
        result
      end

      # based on message_for(test) from the JUnit reporter
      def message_for(test)
        suite = test.class
        name = test.name
        e = test.failure

        if test.passed?
          nil
        elsif test.skipped?
          "Skipped:\n#{name}(#{suite}) [#{location(e)}]:\n#{e.message}\n"
        elsif test.failure
          "Failure:\n#{name}(#{suite}) [#{location(e)}]:\n#{e.message}\n"
        elsif test.error?
          "Error:\n#{name}(#{suite}):\n#{e.message}"
        end
      end

      # taken from the JUnit reporter
      def location(exception)
        last_before_assertion = ''
        exception.backtrace.reverse_each do |s|
          break if s =~ /in .(assert|refute|flunk|pass|fail|raise|must|wont)/
          last_before_assertion = s
        end
        last_before_assertion.sub(/:in .*$/, '')
      end

    end
  end
end
