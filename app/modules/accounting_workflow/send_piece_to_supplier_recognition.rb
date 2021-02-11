class AccountingWorkflow::SendPieceToSupplierRecognition
  def self.execute(pieces)
    pieces.each do |piece|
      new(piece).execute unless piece.is_a_cover
    end
  end

  def initialize(piece)
    @piece = piece
  end

  def execute
  	@piece.recognize_supplier_pre_assignment
    SupplierRecognition::Document.new(name: @piece.name, external_id: @piece.id, content: @piece.content_text, training: false).create
    
    @piece
  end
end