# frozen_string_literal: true

describe Jekyll::TeXyll::Dealiaser do
  describe 'initialized object' do
    subject { described_class.new }

    it { is_expected.to respond_to(:aliases) }
  end

  describe '#add_aliases' do
    subject { described_class.new }

    let(:aliases) do
      [
        { regexp: /(?<code>)/, priority: 10 },
        { regexp: /(?<code>)/, priority: 1000 },
        { regexp: /(?<code>)/, priority: 100 },
        { regexp: /(?<code>)/, priority: 10_000 }
      ].map(&Jekyll::TeXyll::Alias.method(:new))
    end

    before { subject.add_aliases aliases }

    it 'adds all passed aliases' do
      expect(subject.aliases).to match_array aliases
    end

    it 'sorts passed aliases by priority' do
      expect(subject.aliases.map(&:priority)).to eq [10_000, 1000, 100, 10]
    end
  end

  describe '#parse' do
    subject { described_class.new }

    let(:aliases) do
      [
        { regexp: /FOO(?<code>.*?)OOF/, priority: 10 },
        { regexp: /BAR(?<code>.*?)RAB/, priority: 100 },
        { regexp: /BAZ(?<markup>.*?)#(?<code>.*?)ZAB/, priority: 0,
          options: { 'a' => 1, 'b' => 2 } }
      ].map(&Jekyll::TeXyll::Alias.method(:new))
    end

    before { subject.add_aliases aliases }

    it 'replaces the simplest alias' do
      expect(subject.parse(<<~INPUT)).to eq <<~OUTPUT
        FOO code here OOF
      INPUT
        {% texyll --- {}
         %} code here {% endtexyll %}
      OUTPUT
    end

    it 'abides to priorities' do
      expect(subject.parse(<<~INPUT)).to eq <<~OUTPUT
        BAR inside bar the foo FOO code here OOF cannot be seen RAB
      INPUT
        {% texyll --- {}
         %} inside bar the foo FOO code here OOF cannot be seen {% endtexyll %}
      OUTPUT
    end

    it 'interpolates alias options' do
      expect(subject.parse(<<~INPUT)).to eq <<~OUTPUT
        BAZ# code here ZAB
      INPUT
        {% texyll ---
        a: 1
        b: 2
         %} code here {% endtexyll %}
      OUTPUT
    end

    it 'interpolates markup options' do
      expect(subject.parse(<<~INPUT)).to eq <<~OUTPUT
        BAZ { b: 0, c: -1 } # code here ZAB
      INPUT
        {% texyll ---
        a: 1
        b: 0
        c: -1
         %} code here {% endtexyll %}
      OUTPUT
    end
  end
end