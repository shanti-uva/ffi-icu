# encoding: utf-8

require 'spec_helper'

module ICU
  module Collation
    describe "Collation" do
      it "should collate an array of strings" do
        expect(Collation.collate("nb", %w[æ å ø])).to eq %w[æ ø å]
      end
    end

    describe Collator do
      let(:collator) { Collator.new("nb") }

      it "should collate an array of strings" do
        expect(collator.collate(%w[å ø æ])).to eq %w[æ ø å]
      end

      it "should collate an array of Tibetan strings" do
        bo_collator = Collator.new("bo")
        x = ['ཆོས་', 'ཀ', 'དཀོན་','རྐ']
        expect(bo_collator.collate(x)).to eq ['ཀ', 'དཀོན་','རྐ','ཆོས་']
      end

      it "raises an error if argument does not respond to :sort" do
        expect { collator.collate(1) }.to raise_error(ArgumentError)
      end

      it "should return available locales" do
        locales = ICU::Collation.available_locales
        expect(locales).to be_kind_of(Array)
        expect(locales).not_to be_empty
        expect(locales).to include("nb")
      end

      it "should return the locale of the collator" do
        l = collator.locale
        expect(l).to eq "nb"
      end

      it "should compare two strings" do
        expect(collator.compare("blåbærsyltetøy", "blah")).to eq 1
        expect(collator.compare("blah", "blah")).to eq 0
        expect(collator.compare("ba", "bl")).to eq -1
      end

      it "should know if a string is greater than another" do
        expect(collator).to be_greater("z", "a")
        expect(collator).not_to be_greater("a", "z")
      end

      it "should know if a string is greater or equal to another" do
        expect(collator).to be_greater_or_equal("z", "a")
        expect(collator).to be_greater_or_equal("z", "z")
        expect(collator).not_to be_greater_or_equal("a", "z")
      end

      it "should know if a string is equal to another" do
        expect(collator).to be_equal("a", "a")
        expect(collator).not_to be_equal("a", "b")
      end

      it "should return rules" do
        expect(collator.rules).not_to be_empty
        # ö sorts before Ö
        expect(collator.rules.include?('ö<<<Ö')).to be_truthy
      end

    end
  end # Collate
end # ICU
