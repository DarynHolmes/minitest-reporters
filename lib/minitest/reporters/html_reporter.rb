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
        tests_by_groups.each do |suite, tests|
          suite_result = analyze_suite(tests)
          suite_result[:name] = suite.to_s
          suite_result[:tests] = []
          tests.each do |test|
            test_map = {}
            test_map[:name] = friendly_name(test)
            test_map[:classname] = suite.to_s
            test_map[:assertion_count] = test.assertions
            test_map[:time] = test.time
            test_map[:result] = result(test)
            test_map[:message] = test.failure.message unless test.passed?
            test_map[:location] = location(test.failure) unless test.passed?

            suite_result[:tests] << test_map
          end
          suite_result[:tests].sort! { |a, b| compare_tests(a, b) }
          suites << suite_result
        end

        # suites.sort! { |a, b| a[:name].to_s <=> b[:name].to_s }
        suites.sort! { |a, b| compare_suites(a, b) }

        result = renderer.result(binding)

        File.open(html_file, 'w') do |f|
          f.write(result)
        end
      end

      private

      def compare_suites(suite_a, suite_b)
        return 0 if suite_has_errors_or_failures(suite_a) && suite_has_errors_or_failures(suite_b)
        return -1 if suite_has_errors_or_failures(suite_a) && !suite_has_errors_or_failures(suite_b)
        return 1 if !suite_has_errors_or_failures(suite_a) && suite_has_errors_or_failures(suite_b)

        return 0 if suite_has_skipps(suite_a) && suite_has_skipps(suite_b)
        return -1 if suite_has_skipps(suite_a) && !suite_has_skipps(suite_b)
        return 1 if !suite_has_skipps(suite_a) && suite_has_skipps(suite_b)

        suite_a[:name] <=> suite_b[:name]
      end

      def compare_tests(test_a, test_b)
        return 0 if test_failed(test_a) && test_failed(test_b)
        return -1 if test_failed(test_a) && !test_failed(test_b)
        return 1 if !test_failed(test_a) && test_failed(test_b)

        return 0 if test_skipped(test_a) && test_skipped(test_b)
        return -1 if test_skipped(test_a) && !test_skipped(test_b)
        return 1 if !test_skipped(test_a) && test_skipped(test_b)

        test_a[:name] <=> test_b[:name]
      end

      def test_failed(test)
        test[:result] == :error || test[:result] == :fail
      end

      def test_skipped(test)
        test[:result] == :skip
      end

      def suite_has_skipps(suite)
        suite[:skip_count] > 0
      end

      def suite_has_errors_or_failures(suite)
        suite[:fail_count] + suite[:error_count] > 0
      end


      def friendly_name(test)
        groups = test.name.scan(/(test_\d+_)(.*)/i)
        return test.name if groups.empty?
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
