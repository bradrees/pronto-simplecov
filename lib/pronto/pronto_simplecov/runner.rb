module Pronto
  module ProntoSimplecov
    class Simplecov < Runner
      def run
        return [] unless @patches
        return [] if coverage.empty?
        @patches.map { |patch| process(patch) }
                .flatten.compact
      end

      def process(patch)
        file_coverage = coverage[patch.new_file_full_path.to_s]
        return unless file_coverage
        messages = patch.added_lines
             .select { |line| file_coverage.line(line.new_lineno)&.missed? }
             .map { |line| message(line) }
        messages.group_by { |m| m.path }.map do |path, path_messages|
          message = "No test coverage on lines: #{path_messages.map(&:line).join(',')}"
          Message.new(path, path_messages.first.line, :warn, message, nil, self.class)
        end
      end

      def message(line)
        path = line.patch.delta.new_file[:path]
        Message.new(path, line, :error, 'This change has no test coverage', nil, self.class)
      end

      def coverage
        @coverage ||= begin
                        merged_result = SimpleCov::ResultMerger.merged_result
                        return {} if merged_result.nil?
                        Hash[merged_result.files.map { |file| [file.filename, file] }]
                      end
      end
    end
  end
end
