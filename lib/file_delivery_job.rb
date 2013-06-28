class FileDeliveryJob < Struct.new(:pack, :object, :options)
  def perform
    pack.extend FileDeliveryInit::RemotePack
    pack.init_delivery(object, options)
  end
end