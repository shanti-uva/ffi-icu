# encoding: UTF-8

require 'spec_helper'

module ICU
  module Lib
    describe VersionInfo do
      it(:to_a) { expect(subject.to_a).to be_kind_of(Array) }
      it(:to_s) do
        s_subject = subject.to_s
        expect(s_subject).to be_kind_of String
        expect(s_subject).to match /^[0-9.]+$/
      end
    end
  end
end
