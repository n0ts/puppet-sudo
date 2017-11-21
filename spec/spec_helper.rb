require 'rspec-puppet'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |c|
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
end

module ParsedHelper
  def parse_line_helper(line, result_hash)
    hash = @init_records.merge(result_hash)
    record = @provider.parse_line(line)
    hash.each do |h, k|
      expect(record[h.to_sym]).to eq(k)
    end
  end
end
