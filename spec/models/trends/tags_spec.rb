require 'rails_helper'

RSpec.describe Trends::Tags do
  subject { described_class.new }

  let!(:at_time) { DateTime.new(2021, 11, 14, 10, 15, 0) }

  before do
    stub_const 'Trends::Tags::THRESHOLD', 5
    stub_const 'Trends::Tags::REVIEW_THRESHOLD', 10
  end

  describe '#add' do
    let(:tag) { Fabricate(:tag) }

    before do
      subject.add(tag, 1, at_time)
    end

    it 'records history' do
      expect(tag.history.get(at_time).accounts).to eq 1
    end

    it 'records use' do
      expect(subject.send(:recently_used_ids, at_time)).to eq [tag.id]
    end
  end

  describe '#get' do
    pending
  end

  describe '#refresh' do
    let!(:today) { at_time }
    let!(:yesterday) { today - 1.day }

    let!(:tag1) { Fabricate(:tag, name: 'Catstodon', trendable: true) }
    let!(:tag2) { Fabricate(:tag, name: 'DogsOfMastodon', trendable: true) }
    let!(:tag3) { Fabricate(:tag, name: 'OCs', trendable: true) }

    before do
      2.times  { |i| subject.add(tag1, i, yesterday) }
      13.times { |i| subject.add(tag3, i, yesterday) }
      16.times { |i| subject.add(tag1, i, today) }
      4.times  { |i| subject.add(tag2, i, today) }
    end

    context do
      before do
        subject.refresh(yesterday + 12.hours)
        subject.refresh(at_time)
      end

      it 'calculates and re-calculates scores' do
        expect(subject.get(false, 10)).to eq [tag1, tag3]
      end

      it 'omits hashtags below threshold' do
        expect(subject.get(false, 10)).to_not include(tag2)
      end
    end

    it 'decays scores' do
      subject.refresh(yesterday + 12.hours)
      original_score = subject.score(tag3.id)
      expect(original_score).to eq 144.0
      subject.refresh(yesterday + 12.hours + described_class::MAX_SCORE_HALFLIFE)
      decayed_score = subject.score(tag3.id)
      expect(decayed_score).to be <= original_score / 2
    end
  end
end