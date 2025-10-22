require "./spec_helper"

describe TinySoundFont do
  it "has a version number" do
    TinySoundFont::VERSION.should match(/^\d+\.\d+\.\d+$/)
  end
end
