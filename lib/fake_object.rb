class FakeObject
  def initialize
    @object = OpenStruct.new
  end

  def method_missing(name, *args, &block)
    begin
      @object.send(name, args)
    rescue
      begin
        @object.send(name).first
      rescue
        nil
      end
    end
  end
end