class FakeObject < OpenStruct
  def method_missing(name, *args, &block)
    return nil
  end
end